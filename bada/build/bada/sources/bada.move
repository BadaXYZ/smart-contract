/// Module: bada
module bada::bada{
    use sui::bag;
    use sui::event;
    use std::string::String;
    use sui::dynamic_object_field as dof;
    // use std::debug;
    // use sui::package;

    const ECategoryExists: u64 = 0;
    const ENotOwner: u64 = 1;
    const ECategoryDoesNotExists: u64 = 2;

    public struct BadaMarketPlace has key{
        id: UID,
        creator: address,
        // categories: bag::Bag,
    }

    public struct BadaMarketPlaceCategory has key, store{
        id: UID,
        items: vector<ID>,
        items_index: bag::Bag,
    }

    public struct BadaMarketPlaceItemListing has key, store{
        id: UID,
        price: u64,
        owner: address,
    }

    public struct BadaMarketPlaceCreated has copy, drop{
        id : ID,
    }

    public struct BadaMarketPlaceCategoryCreated has copy, drop{
        id : ID,
        name : String
    }

    public struct BadaMarketPlaceItemListingCreated has copy, drop{
        id : ID,
    }

    fun init(ctx: &mut TxContext){
        let bada_marketplace : BadaMarketPlace = BadaMarketPlace{
            id: object::new(ctx),
            creator: ctx.sender(),
            // categories: bag::new(ctx),
        };

        event::emit(BadaMarketPlaceCreated { 
            id: object::id(&bada_marketplace),
        });
        transfer::share_object(bada_marketplace);
    }

    public fun create_category(market_place: &mut BadaMarketPlace, category_name: String, ctx: &mut TxContext){
        assert!(market_place.creator == ctx.sender(), ENotOwner);
        assert!(!dof::exists_(&market_place.id, category_name), ECategoryExists);
        let category : BadaMarketPlaceCategory = BadaMarketPlaceCategory{
            id: object::new(ctx),
            items: vector::empty(),
            items_index: bag::new(ctx),
        };

        event::emit(BadaMarketPlaceCategoryCreated {
            id: object::id(&category),
            name: category_name
        });
        dof::add(&mut market_place.id, category_name, category);
    }

    public fun list_item<T: key + store>(market_place: &mut BadaMarketPlace, item: T, category_name: String, price: u64, ctx: &mut TxContext){
        assert!(dof::exists_(&market_place.id, category_name), ECategoryDoesNotExists);
        let sender = ctx.sender();

        let bada_marketplace_item_listing : BadaMarketPlaceItemListing = BadaMarketPlaceItemListing{
            id: object::new(ctx),
            price,
            owner: sender,
        };

        event::emit(BadaMarketPlaceItemListingCreated {
            id: object::id(&bada_marketplace_item_listing),
        });

        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, category_name);

        dof::add(&mut category.id, category_name , item);

        let index = category.items.length();

        category.items.push_back(object::id(&bada_marketplace_item_listing));
        category.items_index.add(object::id(&bada_marketplace_item_listing), index);
        transfer::share_object(bada_marketplace_item_listing);
    }

    #[test_only]
    public fun call_init(ctx: &mut TxContext){
        init(ctx);
    }
}
