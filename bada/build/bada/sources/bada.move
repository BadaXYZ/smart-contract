/// Module: bada
module bada::bada{
    use sui::bag;
    use sui::event;
    use std::string::String;
    use sui::dynamic_object_field as dof;
    // use sui::dynamic_field as df;
    use sui::coin::{Self, Coin};
    use sui::sui::{Self, SUI};
    use std::type_name::{Self,};
    use std::debug;
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
        categories: vector<ID>,
    }

    public struct BadaMarketPlaceCategory has key, store{
        id: UID,
        name: String,
        items: vector<ID>,
    }

    public struct BadaMarketPlaceItemListing<phantom T: key + store> has key, store{
        id: UID,
        price: u64,
        owner: address,
        category_name : String,
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
        category: ID,
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
            categories: vector::empty(),
        };

        event::emit(BadaMarketPlaceCreated { 
            id: object::id(&bada_marketplace),
        });
        transfer::share_object(bada_marketplace);
    }

    // public fun create_category(market_place: &mut BadaMarketPlace, name: String, ctx: &mut TxContext){
    //     assert!(market_place.creator == ctx.sender(), ENotOwner);
    //     assert!(!dof::exists_(&market_place.id, name), ECategoryExists);
    //     let category : BadaMarketPlaceCategory = BadaMarketPlaceCategory{
    //         id: object::new(ctx),
    //         name,
    //         items: vector::empty(),
    //     };
    //     event::emit(BadaMarketPlaceCategoryCreated {
    //         id: object::id(&category),
    //         name: name
    //     });
    //     market_place.idx.add(category.id.uid_to_inner(), market_place.categories.length());
    //     market_place.categories.push_back(category.id.uid_to_inner());
    //     dof::add(&mut market_place.id, category.id.uid_to_inner(), category); 
    // }

    public fun create_category(market_place: &mut BadaMarketPlace, name: String, ctx: &mut TxContext) : BadaMarketPlaceCategory{
        assert!(market_place.creator == ctx.sender(), ENotOwner);
        assert!(!dof::exists_(&market_place.id, name), ECategoryExists);
        let category : BadaMarketPlaceCategory = BadaMarketPlaceCategory{
            id: object::new(ctx),
            name,
            items: vector::empty(),
        };
        // debug::print(&category);
        event::emit(BadaMarketPlaceCategoryCreated {
            id: object::id(&category),
            name: name
        });
        market_place.idx.add(category.id.uid_to_inner(), market_place.categories.length());
        market_place.categories.push_back(category.id.uid_to_inner());
        category 
    }

    public fun remove_category(market_place: &mut BadaMarketPlace, category : BadaMarketPlaceCategory, ctx: &mut TxContext){
        assert!(market_place.creator == ctx.sender(), ENotOwner);
        assert!(category.items.length() == 0, ECategoryIsNotEmpty);

        let removed_category : BadaMarketPlaceCategory = dof::remove(&mut market_place.id, category.id.uid_to_inner());

        let BadaMarketPlaceCategory {id, name, items: _, } = category;

        event::emit(BadaMarketPlaceCategoryRemoved {
            id: id.uid_to_inner(),
            name: name,
        });

        id.delete();

        let BadaMarketPlaceCategory {id, name: _, items: _, } = removed_category;
        id.delete();
    }

    public fun list_item<T: key + store>(market_place: &mut BadaMarketPlace, item: T, category : &mut BadaMarketPlaceCategory, price: u64, ctx: &mut TxContext){
        let nft_name = type_name::get<T>();
        debug::print(&nft_name);

        // assert!(dof::exists_(&market_place.id, category.name), ECategoryDoesNotExists);
        let sender = ctx.sender();
        
        let mut bada_marketplace_item_listing : BadaMarketPlaceItemListing<T> = BadaMarketPlaceItemListing{
            id: object::new(ctx),
            price,
            owner: sender,
            category_name: category.name
        };

        event::emit(BadaMarketPlaceItemListingCreated {
            id: object::id(&bada_marketplace_item_listing),
        });

        dof::add(&mut bada_marketplace_item_listing.id, b"item" , item);

        let index = category.items.length();

        let idx = BadaMarketPlaceItemIdx{
            index,
            category: category.id.uid_to_inner(),
        };

        category.items.push_back(object::id(&bada_marketplace_item_listing));
        market_place.idx.add(object::id(&bada_marketplace_item_listing), idx);
        transfer::share_object(bada_marketplace_item_listing);
    }

    public fun remove_listed_item<T: key + store>(market_place: &mut BadaMarketPlace, mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(marketplace_item_listing.owner == sender, ENotOwner);

        let item: T = dof::remove(&mut marketplace_item_listing.id, b"item");

        let BadaMarketPlaceItemListing {id, owner, price, category_name} = marketplace_item_listing;

        event::emit(BadaMarketPlaceItemListingRemoved {
            id: id.uid_to_inner(),
            item_id: object::id(&item),
            category_name,
            owner,
            price
        });
        remove_item(market_place, &id);
        id.delete();

        transfer::public_transfer(item, sender);
    }

    fun remove_item(market_place: &mut BadaMarketPlace, id: &UID){
        let idx: BadaMarketPlaceItemIdx = market_place.idx.remove(id.uid_to_inner());
        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, idx.category);

        category.items.swap_remove(idx.index);

        let items_length = category.items.length();
        if (items_length > 0 && items_length != idx.index){
            let moved_item = category.items.borrow(idx.index);

            let new_id = object::id_from_bytes(moved_item.id_to_bytes());

            let _: BadaMarketPlaceItemIdx = market_place.idx.remove(new_id);
            market_place.idx.add(new_id, idx);
        };
    }

    public fun buy_item<T: key + store>(market_place: &mut BadaMarketPlace, mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let item : T = dof::remove(&mut marketplace_item_listing.id, b"item");

        let BadaMarketPlaceItemListing {id, owner, price, category_name} = marketplace_item_listing;

        assert!(payment_coin.value() == price, EInvalidPrice);

        event::emit(BadaMarketPlaceItemBuy {
            id: id.uid_to_inner(),
            item_id: object::id(&item),
            category_name: category_name,
            creator: owner,
            price: price,
            buyer: ctx.sender()
        });

        // remove_item(market_place, &id);
        transfer::public_transfer(payment_coin, owner);
        id.delete();

        transfer::public_transfer(item, ctx.sender());
    }

    // #[test_only]
    // public fun get_created_categorie(market_place: &mut BadaMarketPlace) : &mut BadaMarketPlaceCategory{
    //     let categories = market_place.categories;
    //     let last_category_id = vector::borrow(&categories, categories.length()-1);
    //     let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, *last_category_id);
    //     category
    // }

    #[test_only]
    public fun call_init(ctx: &mut TxContext){
        init(ctx);
    }

    #[test_only]
    public fun get_category_items_length(category: &BadaMarketPlaceCategory): u64{
        category.items.length()
    }
}
