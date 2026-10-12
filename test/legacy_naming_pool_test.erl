-module(legacy_naming_pool_test).
-compile(tuple_calls).
-include_lib("eunit/include/eunit.hrl").

pool_defaults_and_overrides_test() ->
    Default = pool_args([]),
    ?assertEqual(200, proplists:get_value(size, Default)),
    ?assertEqual(50, proplists:get_value(max_overflow, Default)),
    Custom = pool_args([{size, 2}, {size, 9}, {max_overflow, 1},
        {name, wrong_pool}, {worker_module, wrong_worker}, {adapter, mnesia}]),
    ?assertEqual([2], proplists:get_all_values(size, Custom)),
    ?assertEqual([1], proplists:get_all_values(max_overflow, Custom)),
    ?assertEqual([{local, boss_db_pool}], proplists:get_all_values(name, Custom)),
    ?assertEqual([boss_db_controller], proplists:get_all_values(worker_module, Custom)),
    ?assertEqual(mnesia, proplists:get_value(adapter, Custom)),
    ?assertEqual(0, proplists:get_value(max_overflow, pool_args([{max_overflow, 0}]))).

pool_args(Options) ->
    {ok, {_, [{db_controller, {poolboy, start_link, [Args]}, _, _, _, _}]}} = boss_db_sup:init(Options),
    Args.

inflection_and_legacy_names_test() ->
    ?assertEqual("personal_websites", inflector:pluralize("personal_website")),
    ?assertEqual("movement_logs", inflector:pluralize("movement_log")),
    ?assertEqual("children", inflector:pluralize("child")),
    ?assertEqual("people", inflector:pluralize("person")),
    ?assertEqual("child", inflector:singularize("children")),
    ?assertEqual("peopleal_website", inflector:legacy_pluralize("personal_website")),
    ?assertEqual("movesment_log", inflector:legacy_pluralize("movement_log")),
    ?assertEqual("peopleal_website", inflector:tableize("PersonalWebsite")),
    ?assertEqual("PersonalWebsite", inflector:moduleize("peopleal_website")),
    load_fixture(),
    Row = personal_website:new("personal_website-2", "legacy"),
    ?assertEqual("peopleal_website", Row:database_table()),
    ?assertEqual("peopleal_website", boss_record_lib:database_table(personal_website)).

load_fixture() ->
    File = filename:join(os:getenv("TMPDIR"), "personal_website.erl"),
    ok = file:write_file(File, <<"-module(personal_website, [Id, Name]).\n">>),
    {ok, personal_website} = boss_record_compiler:compile(File).

pool_limits_and_recovery_test_() ->
    {timeout, 15, fun pool_limits_and_recovery/0}.

pool_limits_and_recovery() ->
    {ok, Sup} = boss_db_sup:start_link([{adapter, mnesia}, {size, 2}, {max_overflow, 1}]),
    try
        ?assertEqual({ready, 2, 0, 0}, poolboy:status(boss_db_pool)),
        Workers = [poolboy:checkout(boss_db_pool, false) || _ <- lists:seq(1, 3)],
        ?assert(lists:all(fun is_pid/1, Workers)),
        ?assertEqual(full, poolboy:checkout(boss_db_pool, false)),
        [poolboy:checkin(boss_db_pool, W) || W <- Workers],
        wait(fun() -> poolboy:status(boss_db_pool) =:= {ready, 2, 0, 0} end, 200),
        [Dead | _] = gen_server:call(boss_db_pool, get_avail_workers),
        Monitor = monitor(process, Dead), exit(Dead, kill),
        receive {'DOWN', Monitor, process, Dead, killed} -> ok after 2000 -> error(worker_not_stopped) end,
        wait(fun() ->
            Available = gen_server:call(boss_db_pool, get_avail_workers),
            length(Available) =:= 2 andalso not lists:member(Dead, Available)
        end, 200),
        OldPool = whereis(boss_db_pool), exit(OldPool, kill),
        wait(fun() ->
            P = whereis(boss_db_pool),
            is_pid(P) andalso P =/= OldPool andalso poolboy:status(P) =:= {ready, 2, 0, 0}
        end, 200),
        ?assert(is_process_alive(Sup))
    after
        gen_server:stop(Sup)
    end.

wait(Fun, Attempts) when Attempts > 0 ->
    case catch Fun() of
        true -> ok;
        _ -> receive after 10 -> wait(Fun, Attempts - 1) end
    end;
wait(_, 0) -> error(recovery_timeout).

legacy_news_topic_test() ->
    load_fixture(),
    {ok, News} = boss_news_controller:start_link(),
    Parent = self(),
    Callback = fun(Event, Row) -> Parent ! {legacy_news, Event, Row} end,
    try
        {ok, _} = boss_news:watch("peopleal_website", Callback),
        {ok, _} = boss_news:watch("personal_websites", fun(_, _) -> Parent ! renamed_topic end),
        ok = boss_news:created("personal_website-2", [{name, "legacy"}]),
        receive {legacy_news, created, Row} -> ?assertEqual("personal_website-2", Row:id())
        after 2000 -> error(created_notification_missing) end,
        ok = boss_news:deleted("personal_website-2", [{name, "legacy"}]),
        receive {legacy_news, deleted, _} -> ok after 2000 -> error(deleted_notification_missing) end,
        receive renamed_topic -> error(news_topic_renamed) after 20 -> ok end
    after
        gen_server:stop(News),
        code:purge(personal_website), code:delete(personal_website)
    end.
