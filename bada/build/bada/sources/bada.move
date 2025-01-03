/// Module: bada
module bada::bada{
    use sui::bag;
    use sui::event;
    use std::string::String;
    use sui::dynamic_object_field as dof;
    // use sui::dynamic_field as df;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::Balance;
    use std::type_name::{Self,};
    use std::debug;
    // use sui::package;

    const ECategoryExists: u64 = 0;
    const ENotOwner: u64 = 1;
    const ECategoryDoesNotExists: u64 = 2;
    const ECategoryIsNotEmpty: u64 = 3;
    const EInvalidPrice: u64 = 4;
    const EAddressBidded: u64 = 5;
    const EInvalidBid: u64 = 6;

    public struct BadaMarketPlace has key{
        id: UID,
        creator: address,
        idx: bag::Bag,
        categories: vector<String>,
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
        bids: bag::Bag,
        bidders: vector<address>,
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
        category: String,
    }

    public struct BadaMarketPlaceItemBidIdx has store{
        index : u64,
        bid :  Balance<SUI>,
    }

    public struct BadaMarketPlaceItemBuy has copy, drop{
        id : ID,
        item_id : ID,
        category_name : String,
        creator : address,
        price : u64,
        buyer : address
    }

    public struct BadaMarketPlaceItemBid has key, store {
        id: UID,
        bidder: address,
        amount:  u64,
        item_id: ID,
    }

    public struct BadaMarketPlaceItemBidPlaced has copy, drop {
        id: ID,
        item_id: ID,
        bidder: address,
        amount: u64,
    }

    public struct BadaMarketPlaceItemBidCanceled has copy, drop {
        id: ID,
        item_id: ID,
        bidder: address,
        amount: u64,
    }

    public struct BadaMarketPlaceItemBidAccepted has copy, drop {
        id: ID,
        item_id: ID,
        bidder: address,
        amount: u64,
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

    public fun create_category(market_place: &mut BadaMarketPlace, name: String, ctx: &mut TxContext){
        assert!(market_place.creator == ctx.sender(), ENotOwner);
        assert!(!dof::exists_(&market_place.id, name), ECategoryExists);
        let category : BadaMarketPlaceCategory = BadaMarketPlaceCategory{
            id: object::new(ctx),
            name,
            items: vector::empty(),
        };
        event::emit(BadaMarketPlaceCategoryCreated {
            id: object::id(&category),
            name: name
        });
        market_place.idx.add(category.name, market_place.categories.length());
        market_place.categories.push_back(category.name);
        dof::add(&mut market_place.id, category.name, category);
    }

    public fun remove_category(market_place: &mut BadaMarketPlace, category_name: String, ctx: &mut TxContext){
        assert!(market_place.creator == ctx.sender(), ENotOwner);
        let category : &BadaMarketPlaceCategory = dof::borrow(&market_place.id, category_name);
        assert!(category.items.length() == 0, ECategoryIsNotEmpty);

        let removed_category : BadaMarketPlaceCategory = dof::remove(&mut market_place.id, category_name);

        event::emit(BadaMarketPlaceCategoryRemoved {
            id: removed_category.id.uid_to_inner(),
            name: removed_category.name,
        });

        let BadaMarketPlaceCategory {id, name: _, items: _, } = removed_category;
        id.delete();

        let idx: u64 = market_place.idx.remove(category_name);
        market_place.categories.swap_remove(idx);
        let categories_length = market_place.categories.length();
        if (categories_length > 0 && categories_length != idx){
            let moved_category = market_place.categories.borrow(idx);

            let _: u64 = market_place.idx.remove(*moved_category);
            market_place.idx.add(*moved_category, idx);
        };
    }

    public fun list_item<T: key + store>(market_place: &mut BadaMarketPlace, item: T, category_name: String, price: u64, ctx: &mut TxContext){
        // let nft_name = type_name::get<T>();
        // debug::print(&nft_name);

        assert!(dof::exists_(&market_place.id, category_name), ECategoryDoesNotExists);
        let sender = ctx.sender();
        let category : &mut BadaMarketPlaceCategory = dof::borrow_mut(&mut market_place.id, category_name);
        let mut bada_marketplace_item_listing : BadaMarketPlaceItemListing<T> = BadaMarketPlaceItemListing{
            id: object::new(ctx),
            price,
            owner: sender,
            category_name: category.name,
            bids: bag::new(ctx),
            bidders: vector::empty(),
        };

        event::emit(BadaMarketPlaceItemListingCreated {
            id: object::id(&bada_marketplace_item_listing),
        });

        dof::add(&mut bada_marketplace_item_listing.id, b"item" , item);

        let index = category.items.length();

        let idx = BadaMarketPlaceItemIdx{
            index,
            category: category.name,
        };

        category.items.push_back(object::id(&bada_marketplace_item_listing));
        market_place.idx.add(object::id(&bada_marketplace_item_listing), idx);
        transfer::share_object(bada_marketplace_item_listing);
    }

    public fun remove_listed_item<T: key + store>(market_place: &mut BadaMarketPlace, mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(marketplace_item_listing.owner == sender, ENotOwner);

        let item: T = dof::remove(&mut marketplace_item_listing.id, b"item");

        // let BadaMarketPlaceItemListing {id, owner, price, category_name, bids, bidders: _} = marketplace_item_listing;

        event::emit(BadaMarketPlaceItemListingRemoved {
            id: marketplace_item_listing.id.uid_to_inner(),
            item_id: object::id(&item),
            category_name : marketplace_item_listing.category_name,
            owner: marketplace_item_listing.owner,
            price: marketplace_item_listing.price,
        });
        
        return_bids(market_place,marketplace_item_listing, ctx);
        // id.delete();

        transfer::public_transfer(item, sender);
        // bids.destroy_empty();
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

    public fun buy_item<T: key + store>(market_place: &mut BadaMarketPlace,mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let item : T = dof::remove(&mut marketplace_item_listing.id, b"item");
        // let BadaMarketPlaceItemListing {id, owner, price, category_name, bids, bidders: _} = marketplace_item_listing;

        assert!(payment_coin.value() == marketplace_item_listing.price, EInvalidPrice);

        event::emit(BadaMarketPlaceItemBuy {
            id: marketplace_item_listing.id.uid_to_inner(),
            item_id: object::id(&item),
            category_name: marketplace_item_listing.category_name,
            creator: marketplace_item_listing.owner,
            price: marketplace_item_listing.price,
            buyer: ctx.sender(),
        });

        // remove_item(market_place, &marketplace_item_listing.id);
        transfer::public_transfer(payment_coin, marketplace_item_listing.owner);
        // id.delete();
        // bids.destroy_empty();

        transfer::public_transfer(item, ctx.sender());
        return_bids(market_place,marketplace_item_listing, ctx);
    }

    public fun make_bid<T: key + store>(marketplace_item_listing: &mut BadaMarketPlaceItemListing<T>, payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(!bag::contains(&marketplace_item_listing.bids, sender), EAddressBidded);

        let bid = BadaMarketPlaceItemBid {
            id: object::new(ctx),
            bidder: sender,
            amount: payment_coin.value(),
            item_id: object::id(marketplace_item_listing),
        };

        let idx = BadaMarketPlaceItemBidIdx{
            index: marketplace_item_listing.bidders.length(),
            bid: payment_coin.into_balance(),
        };

        marketplace_item_listing.bids.add(sender, idx);
        marketplace_item_listing.bidders.push_back(sender);

        event::emit(BadaMarketPlaceItemBidPlaced {
            id: object::id(&bid),
            item_id: object::id(marketplace_item_listing),
            bidder: sender,
            amount: bid.amount,
        });

        transfer::public_share_object(bid);
    }

    public fun cancel_bid<T: key + store>(marketplace_item_listing: &mut BadaMarketPlaceItemListing<T>, bid: BadaMarketPlaceItemBid, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(marketplace_item_listing.bidders.contains(&sender) && bid.bidder == sender, EInvalidBid);

        let BadaMarketPlaceItemBid {id, bidder, amount, item_id: _} = bid;

        event::emit(BadaMarketPlaceItemBidCanceled {
            id: id.uid_to_inner(),
            item_id: object::id(marketplace_item_listing),
            bidder,
            amount,
        });

        return_bid(marketplace_item_listing, ctx);
        id.delete();
    }

    #[allow(lint(self_transfer))]
    fun return_bid<T: key + store>(marketplace_item_listing: &mut BadaMarketPlaceItemListing<T>, ctx: &mut TxContext){
        let sender = ctx.sender();
        let idx : BadaMarketPlaceItemBidIdx = marketplace_item_listing.bids.remove(sender);

        marketplace_item_listing.bidders.swap_remove(idx.index);
        let BadaMarketPlaceItemBidIdx {index, mut bid} = idx;

        let bidders_length = marketplace_item_listing.bidders.length();
        if (bidders_length > 0 && bidders_length != index){
            let moved_bidder_address = marketplace_item_listing.bidders.borrow(index);

            let moved_bidder: BadaMarketPlaceItemBidIdx = marketplace_item_listing.bids.remove(*moved_bidder_address);
            marketplace_item_listing.bids.add(*moved_bidder_address, moved_bidder);
        };
        let amount = bid.value();
        let balance = coin::take(&mut bid, amount, ctx);
        transfer::public_transfer(balance, sender);

        bid.destroy_zero();
    }

    public fun accept_bid<T: key + store>(market_place: &mut BadaMarketPlace,mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, bid: BadaMarketPlaceItemBid, ctx: &mut TxContext){
        assert!(ctx.sender() == marketplace_item_listing.owner, ENotOwner);

        let item : T = dof::remove(&mut marketplace_item_listing.id, b"item");
        let BadaMarketPlaceItemBid {id, bidder, amount, item_id: _} = bid;

        event::emit(BadaMarketPlaceItemBidAccepted {
            id: id.uid_to_inner(),
            item_id: object::id(&item),
            bidder,
            amount,
        });

        let idx : BadaMarketPlaceItemBidIdx = marketplace_item_listing.bids.remove(bidder);
        let BadaMarketPlaceItemBidIdx {index, mut bid} = idx;
        marketplace_item_listing.bidders.remove(index);

        let amount = bid.value();
        let balance = coin::take(&mut bid, amount, ctx);
        transfer::public_transfer(item, bidder);
        transfer::public_transfer(balance, marketplace_item_listing.owner);
        bid.destroy_zero();
        id.delete();
        return_bids(market_place,marketplace_item_listing, ctx);
    }

    fun return_bids<T: key + store>(market_place: &mut BadaMarketPlace,mut marketplace_item_listing: BadaMarketPlaceItemListing<T>, ctx : &mut TxContext){
        let mut bidders = marketplace_item_listing.bidders;
        let mut i = 0;
        while(i < bidders.length()){
            let bidder = bidders.remove(i);
            let idx : BadaMarketPlaceItemBidIdx = marketplace_item_listing.bids.remove(bidder);
            let BadaMarketPlaceItemBidIdx {index: _, mut bid} = idx;

            let amount = bid.value();
            let balance = coin::take(&mut bid, amount, ctx);
            transfer::public_transfer(balance, bidder);
            i = i + 1;
            bid.destroy_zero();
        };

        remove_item(market_place, &marketplace_item_listing.id);

        let BadaMarketPlaceItemListing {id, owner: _, price: _, category_name: _, bids, bidders: _} = marketplace_item_listing;
        id.delete();
        bids.destroy_empty();
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