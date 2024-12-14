#[test_only]
module bada::bada_tests{
    use bada::bada;
    use sui::test_scenario as ts;
    use std::debug;
    // use sui::dynamic_object_field as dof;

    const ENotImplemented: u64 = 0;

    #[test]
    fun test_bada_init() {
        let creator = @0xA;

        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            
            let bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            ts::return_shared(bada_marketplace);
        };
        scenerio.end();
    }

    #[test]
    fun test_bada_create_category() {
        let creator = @0xA;
        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            // debug::print(&bada_marketplace_id);
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            // debug::print(&bada_marketplace);
            ts::return_shared(bada_marketplace);
            
        };

        let effects = scenerio.next_tx(creator);
        let eff = ts::num_user_events(&effects);
        debug::print(&eff);
        scenerio.end();
    }

    #[test, expected_failure(abort_code = ::bada::bada_tests::ENotImplemented)]
    fun test_bada_fail() {
        abort ENotImplemented
    }
}

