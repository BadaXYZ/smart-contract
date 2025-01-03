
/// Module: bada2
module bada2::listing{
    // use sui::bag;
    use sui::event;
    // use std::string::String;
    use sui::dynamic_object_field as dof;
    // use sui::dynamic_field as df;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::Balance;
    use std::ascii::String as AString;
    use std::type_name::{Self,};
    use bada2::utils::calculate_percent_amount;

    const ENotOwner: u64 = 1;
    const EInvalidPrice: u64 = 4;

    public struct BadaMarketPlaceListing has key{
        id: UID,
        royalties: u64,
        beneficiary: address,
    }

    public struct BadaMarketPlaceItemListing has key, store{
        id: UID,
        price: u64,
        seller: address,
    }
    
    // public struct BadaMarketPlaceCreated has copy, drop{
    //     id : ID,
    // }


    // public struct BadaMarketPlaceItemListingCreated has copy, drop{
    //     listing_id : ID,
    //     item_id : ID,
    //     seller : address,
    //     price : u64,
    //     commission : u64,
    //     beneficiary : address
    // }

    // public struct BadaMarketPlaceItemListingRemoved has copy, drop{
    //     listing_id : ID,
    //     item_id : ID,
    //     seller : address,
    //     price : u64,
    //     commission : u64,
    //     beneficiary : address
    // }

    // public struct BadaMarketPlaceItemBuy has copy, drop{
    //     listing_id : ID,
    //     item_id : ID,
    //     seller : address,
    //     price : u64,
    //     buyer : address,
    //     commission : u64,
    //     beneficiary : address
    // }

    fun init(ctx: &mut TxContext){
        let bada_marketplace_listing : BadaMarketPlaceListing = BadaMarketPlaceListing{
            id: object::new(ctx),
            royalties: 0,
            beneficiary : @0xa
        };

        // event::emit(BadaMarketPlaceCreated { 
        //     id: object::id(&bada_marketplace),
        // });
        transfer::share_object(bada_marketplace_listing);
    }

    public fun update_beneficiary(market_place_listing: &mut BadaMarketPlaceListing, beneficiary: address, ctx: &mut TxContext){
        market_place_listing.beneficiary = beneficiary;
    }

    public fun update_royalties(market_place_listing: &mut BadaMarketPlaceListing, royalties: u64, ctx: &mut TxContext){
        market_place_listing.royalties = royalties;
    }

    public fun list_item<T: key + store>(bada_marketplace_listing: &mut BadaMarketPlaceListing, item: T, price: u64, ctx: &mut TxContext){
        let sender = ctx.sender();
        let mut bada_marketplace_item_listing : BadaMarketPlaceItemListing = BadaMarketPlaceItemListing{
            id: object::new(ctx),
            price,
            seller: sender,
        };

        
        let listing_id = object::id(&bada_marketplace_item_listing);
        // event::emit(BadaMarketPlaceItemListingCreated {
        //     listing_id: listing_id,
        //     item_id: object::id(&item),
        //     seller: sender,
        //     price,
        //     commission,
        //     beneficiary
        // });
        dof::add(&mut bada_marketplace_item_listing.id, b"item" , item);
        dof::add(&mut bada_marketplace_listing.id, listing_id, bada_marketplace_item_listing);   
    }

    public fun unlisted_item<T: key + store>(bada_marketplace_listing: &mut BadaMarketPlaceListing, item_listing_id: ID, ctx: &mut TxContext){
        let sender = ctx.sender();

        let mut listing: BadaMarketPlaceItemListing = dof::remove(&mut bada_marketplace_listing.id, item_listing_id);
        assert!(listing.seller == sender, ENotOwner);
        let item: T = dof::remove(&mut listing.id, b"item");
        
        let BadaMarketPlaceItemListing {id, price:_, seller:_} = listing;
        // event::emit(BadaMarketPlaceItemListingRemoved {
        //     listing_id: item_listing_id,
        //     item_id: object::id(&item),
        //     seller,
        //     price: price,
        //     commission,
        //     beneficiary
        // });
        transfer::public_transfer(item, sender);
        id.delete();   
    }

    public fun buy_item<T: key + store>(bada_marketplace_listing: &mut BadaMarketPlaceListing,item_listing_id: ID, mut payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let mut listing: BadaMarketPlaceItemListing = dof::remove(&mut bada_marketplace_listing.id, item_listing_id);

        assert!(payment_coin.value() == listing.price, EInvalidPrice);

        let item: T = dof::remove(&mut listing.id, b"item");
        let BadaMarketPlaceItemListing {id, price, seller} = listing;
        id.delete();
        transfer::public_transfer(item, ctx.sender());

        let commision_coin = coin::split(&mut payment_coin, calculate_percent_amount(price, bada_marketplace_listing.royalties), ctx);
        transfer::public_transfer(commision_coin, bada_marketplace_listing.beneficiary);
        transfer::public_transfer(payment_coin, seller);

        // event::emit(BadaMarketPlaceItemBuy {
        //     listing_id:item_listing_id,
        //     item_id: object::id(&item),
        //     seller,
        //     price: price,
        //     buyer: ctx.sender(),
        //     commission,
        //     beneficiary: bada_marketplace_listing.beneficiary,
        // });
    }

    #[test_only]
    public fun call_init(ctx: &mut TxContext){
        init(ctx);
    }
}
