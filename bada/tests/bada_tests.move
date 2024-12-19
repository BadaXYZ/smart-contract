#[test_only]
module bada::bada_tests{
    use bada::bada;
    use sui::test_scenario as ts;
    use std::debug;
    use bada::nft;
    // use sui::coin;
    // use sui::sui::SUI;

    // use sui::dynamic_object_field as dof;

    const ENotImplemented: u64 = 0;

    #[test]
    fun test_bada_init() {
        let creator = @0xA;

        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };
        let effects = scenerio.next_tx(creator);
        assert!(effects.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test]
    fun test_bada_create_category(){
        let creator = @0xA;
        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects = scenerio.next_tx(creator);
        assert!(effects.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test]
    fun delete_category(){
        let creator = @0xA;
        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::remove_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects = scenerio.next_tx(creator);
        assert!(effects.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test, expected_failure(abort_code = ::bada::bada::ENotOwner)]
    fun delete_category_fail(){
        let creator = @0xA;
        let random_guy = @0xB;
        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        scenerio.next_tx(random_guy);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::remove_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects = scenerio.next_tx(creator);
        assert!(effects.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test]
    fun test_bada_create_category_and_list_item(){
        let creator = @0xA;
        let seller = @0xB;

        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };

        scenerio.next_tx(seller);
        {
            nft::mint_to_sender(b"name", b"description", b"url", scenerio.ctx());
        };

        let effects_create_nft = scenerio.next_tx(seller);
        assert!(effects_create_nft.num_user_events() == 1, 1); 
        {   
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            let nft = scenerio.take_from_sender<nft::NFT>();
            bada::list_item(&mut bada_marketplace, nft, b"test".to_string(),10, scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects_list_nft = scenerio.next_tx(seller);
        assert!(effects_list_nft.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test, expected_failure(abort_code = ::bada::bada::ECategoryIsNotEmpty)]
    fun delete_category_fail2(){
        let creator = @0xA;
        let seller = @0xB;

        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };

        scenerio.next_tx(seller);
        {
            nft::mint_to_sender(b"name", b"description", b"url", scenerio.ctx());
        };

        let effects_create_nft = scenerio.next_tx(seller);
        assert!(effects_create_nft.num_user_events() == 1, 1); 
        {   
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            let nft = scenerio.take_from_sender<nft::NFT>();
            bada::list_item(&mut bada_marketplace, nft, b"test".to_string(),10, scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::remove_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects = scenerio.next_tx(creator);
        assert!(effects.num_user_events() == 1, 1); 
        scenerio.end();
    }

    #[test]
    fun test_remove_listed_item(){
        let creator = @0xA;
        let seller = @0xB;

        let mut scenerio = ts::begin(creator);
        {
            bada::call_init(scenerio.ctx());
        };

        scenerio.next_tx(creator);
        {
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };

        scenerio.next_tx(seller);
        {
            nft::mint_to_sender(b"name", b"description", b"url", scenerio.ctx());
        };

        let effects_create_nft = scenerio.next_tx(seller);
        assert!(effects_create_nft.num_user_events() == 1, 1); 
        {   
            let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
            let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
            let nft = scenerio.take_from_sender<nft::NFT>();
            bada::list_item(&mut bada_marketplace, nft, b"test".to_string(),10, scenerio.ctx());
            ts::return_shared(bada_marketplace);
        };
        let effects_list_nft = scenerio.next_tx(seller);
        assert!(effects_list_nft.num_user_events() == 1, 1); 
        scenerio.end();
    }

    // #[test]
    // fun test_bada_create_category_and_list_item(){
    //     let creator = @0xA;
    //     let buyer = @0xB;
    //     let mut scenerio = ts::begin(creator);
    //     {
    //         bada::call_init(scenerio.ctx());
    //     };

    //     scenerio.next_tx(creator);
    //     {
    //         let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
    //         // debug::print(&bada_marketplace_id);
    //         let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
    //         bada::create_category(&mut bada_marketplace, b"test".to_string(), scenerio.ctx());
    //         // // debug::print(created_category);

    //         let nft = nft::mint_to_sender(b"name", b"description", b"url", scenerio.ctx());

    //         // debug::print(&nft);

    //         bada::list_item(&mut bada_marketplace, nft, b"test".to_string(),10, scenerio.ctx());
    //         ts::return_shared(bada_marketplace);
    //     };

    //     // let effects = scenerio.next_tx(creator);
    //     // let eff = ts::num_user_events(&effects);
    //     // debug::print(&eff);

    //     scenerio.next_tx(buyer);
    //     {
    //         let mut bada_marketplace_id = ts::most_recent_id_shared<bada::BadaMarketPlace>();
    //         let mut bada_marketplace : bada::BadaMarketPlace = scenerio.take_shared_by_id(bada_marketplace_id.extract());
    //         let mut listing_id = ts::most_recent_id_shared<bada::BadaMarketPlaceItemListing<nft::NFT>>();
    //         // debug::print(&listing_id);
    //         assert!(listing_id.is_some(), 1);

    //         let listing: bada::BadaMarketPlaceItemListing<nft::NFT> = scenerio.take_shared_by_id(listing_id.extract());
    //         let sui_coin = coin::mint_for_testing<SUI>(10, scenerio.ctx());
    //         bada::buy_item(&mut bada_marketplace, listing, sui_coin, scenerio.ctx());
    //         ts::return_shared(bada_marketplace);
    //     };
    //     scenerio.end();
    // }

    #[test, expected_failure(abort_code = ::bada::bada_tests::ENotImplemented)]
    fun test_bada_fail() {
        abort ENotImplemented
    }
}

