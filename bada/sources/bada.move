/// Module: bada
module bada::bada{
    use sui::bag;
    use sui::event;
    use std::string::String;
    use sui::dynamic_object_field as dof;
    use sui::coin::{Self, Coin};
    use sui::sui::{Self, SUI};
    // use std::debug;
    // use sui::package;

    const ECategoryExists: u64 = 0;
    const ENotOwner: u64 = 1;
    const ECategoryDoesNotExists: u64 = 2;
    const ECategoryIsNotEmpty: u64 = 3;
    const EInvalidPrice: u64 = 4;

    public struct BadaMarketPlace has key{
        id: UID,
        creator: address,
        idx: bag::Bag,
    }

    public struct BadaMarketPlaceCategory has key, store{
        id: UID,
        items: vector<ID>,
        items_index: bag::Bag,
    }

    public struct BadaMarketPlaceItemListing<phantom T: key + store> has key, store{
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

    public struct BadaMarketPlaceItemListingRemoved has copy, drop{
        id : ID,
        item_id : ID,
        category_name : String,
        owner : address,
        price : u64
    }

    public struct BadaMarketPlaceCategoryRemoved has copy, drop{
        id : ID,
        name : String
    }

    public struct BadaMarketPlaceItemIdx has copy, drop, store{
        index : u64,
        category_name : String,
    }

    public struct BadaMarketPlaceItemBuy has copy, drop{
        id : ID,
        item_id : ID,
        category_name : String,
        creator : address,
        price : u64,
        buyer : address
    }

    fun init(ctx: &mut TxContext){
        let bada_marketplace : BadaMarketPlace = BadaMarketPlace{
            id: object::new(ctx),
            creator: ctx.sender(),
            idx: bag::new(ctx),
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

    public fun remove_category(market_place: &mut BadaMarketPlace, category_name: String, ctx: &mut TxContext){
        assert!(market_place.creator == ctx.sender(), ENotOwner);

        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, category_name);
        assert!(category.items.length() == 0, ECategoryIsNotEmpty);

        let removed_category : BadaMarketPlaceCategory = dof::remove(&mut market_place.id, category_name);

        event::emit(BadaMarketPlaceCategoryRemoved {
            id: object::id(&removed_category),
            name: category_name
        });
    }

    public fun list_item<T: key + store>(market_place: &mut BadaMarketPlace, item: T, category_name: String, price: u64, ctx: &mut TxContext){
        assert!(dof::exists_(&market_place.id, category_name), ECategoryDoesNotExists);
        let sender = ctx.sender();

        let mut bada_marketplace_item_listing : BadaMarketPlaceItemListing<T> = BadaMarketPlaceItemListing{
            id: object::new(ctx),
            price,
            owner: sender,
        };

        event::emit(BadaMarketPlaceItemListingCreated {
            id: object::id(&bada_marketplace_item_listing),
        });
        dof::add(&mut bada_marketplace_item_listing.id, category_name , item);
        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, category_name);

        let index = category.items.length();

        let idx = BadaMarketPlaceItemIdx{
            index,
            category_name
        };

        category.items.push_back(object::id(&bada_marketplace_item_listing));
        market_place.idx.add(object::id(&bada_marketplace_item_listing), idx);
        transfer::share_object(bada_marketplace_item_listing);
    }

    public fun remove_listed_item<T: key + store>(market_place: &mut BadaMarketPlace, marketplace_item_listing: BadaMarketPlaceItemListing<T>, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(marketplace_item_listing.owner == sender, ENotOwner);

        let item: T = dof::remove(&mut marketplace_item_listing.id, name);

        let BadaMarketPlaceItemListing {id, owner, price} = marketplace_item_listing;

        let idx: &BadaMarketPlaceItemIdx = bag::borrow(&market_place.idx, id.uid_to_inner());
        event::emit(BadaMarketPlaceItemListingRemoved {
            id: id.uid_to_inner(),
            item_id: object::id(&item),
            category_name: idx.category_name,
            owner,
            price
        });
        remove_listed_category_items(market_place, &id);
        id.delete();
    }

    fun remove_listed_category_items(market_place: &mut BadaMarketPlace, id: &UID){
        let idx: BadaMarketPlaceItemIdx = market_place.idx.remove(id.uid_to_inner());
        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, idx.category_name);

        category.items.swap_remove(idx.index);

        let items_length = category.items.length();
        if (items_length > 0 && items_length != idx.index){
            let moved_item = category.items.borrow(idx.index);

            let new_id = object::id_from_bytes(moved_item.id_to_bytes());

            let _: BadaMarketPlaceItemIdx = market_place.idx.remove(new_id);
            market_place.idx.add(new_id, idx);
        };
    }

    public fun buy_item<T: key + store>(market_place: &mut BadaMarketPlace, marketplace_item_listing: BadaMarketPlaceItemListing<T>, payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let item : T = dof::remove(&mut marketplace_item_listing.id, name);

        let BadaMarketPlaceItemListing {id, owner, price} = marketplace_item_listing;

        assert!(payment_coin.value() == price, EInvalidPrice);

        event::emit(BadaMarketPlaceItemBuy {
            id: id.uid_to_inner(),
            item_id: object::id(&item),
            category_name: name,
            creator: owner,
            price,
            buyer: ctx.sender()
        });

        remove_listed_category_items(market_place, &id);
        transfer::public_transfer(payment_coin, owner);
        id.delete();
    }

    #[test_only]
    public fun call_init(ctx: &mut TxContext){
        init(ctx);
    }
}
