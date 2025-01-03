module bada2::bidding{
    use sui::dynamic_object_field as dof;
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::Balance;
    use std::ascii::String as AString;
    use std::type_name::{Self,};
    use bada2::utils::calculate_percent_amount;
    // use sui::package;

    public struct BadaMarketPlaceBidding has key{
        id: UID,
        royalties: u64,
        beneficiary: address,
    }

    // public struct BadaMarketPlaceBiddingCreated has copy, drop{
    //     id : ID,
    //     royalties: u64
    // }

    public struct BadaMarketPlaceItemBid has key, store{
        id: UID,
        item_type: AString,
        nft_id : ID,
        owner: address,
        balance: Balance<SUI>,
    }

    // public struct BadaMarketPlaceItemBidAdded has copy, drop{
    //     id : ID,
    //     item_type: AString,
    //     nft_id : ID,
    //     owner: address,
    //     amount: u64
    // }

    // public struct BadaMarketPlaceItemBidCanceled has copy, drop{
    //     id : ID,
    //     item_type: AString,
    //     nft_id : ID,
    //     owner: address,
    //     amount: u64
    // }

    public struct BadaMarketPlaceItemBidAcceptedEvent has copy, drop {
        bid_id: ID,
        item_type: AString,
        nft_id: ID,
        seller: address,
        buyer: address,
        price: u64,
        commission: u64,
        beneficiary: address,
    }

    fun init(ctx: &mut TxContext){
        let bada_marketplace_bidding : BadaMarketPlaceBidding = BadaMarketPlaceBidding{
            id: object::new(ctx),
            royalties: 0,
            beneficiary: @0xa,
        };

        // event::emit(BadaMarketPlaceBiddingCreated { 
        //     id: object::id(&bada_marketplace_bidding),
        //     royalties: royalties,
        // });
        transfer::share_object(bada_marketplace_bidding);
    }

    public fun update_royalties(market_place_bidding: &mut BadaMarketPlaceBidding, royalties: u64, ctx: &mut TxContext){
        market_place_bidding.royalties = royalties;
    }

    public fun update_beneficiary(market_place_bidding: &mut BadaMarketPlaceBidding, beneficiary: address, ctx: &mut TxContext){
        market_place_bidding.beneficiary = beneficiary;
    }

    public fun make_bid<T: key + store>(market_place_bidding: &mut BadaMarketPlaceBidding, nft_id: ID, payment_coin: Coin<SUI>, ctx: &mut TxContext){
        let sender = ctx.sender();

        let item_type_name = type_name::get<T>();
        let bid = BadaMarketPlaceItemBid {
            id: object::new(ctx),
            item_type: *item_type_name.borrow_string(),
            nft_id,
            owner: sender,
            balance: payment_coin.into_balance(),
        };

        let bid_id = object::id(&bid);

        // event::emit(BadaMarketPlaceItemBidAdded {
        //     id: bid_id,
        //     item_type: *item_type_name.borrow_string(),
        //     nft_id,
        //     owner: sender,
        //     amount: payment_coin.value(),
        // });
        dof::add(&mut market_place_bidding.id,bid_id, bid);
    }
    
    #[allow(lint(self_transfer))]
    public fun cancel_bid<T: key + store>(market_place_bidding: &mut BadaMarketPlaceBidding, bid_id: ID, ctx: &mut TxContext){
        let sender = ctx.sender();
        assert!(dof::exists_(&market_place_bidding.id, bid_id), 0);

        let bid: BadaMarketPlaceItemBid = dof::remove(&mut market_place_bidding.id, bid_id);
        assert!(bid.owner == sender, 0);

        let BadaMarketPlaceItemBid {id, item_type, nft_id, owner, mut balance} = bid;
        // event::emit(BadaMarketPlaceItemBidCanceled {
        //     id: id.uid_to_inner(),
        //     item_type,
        //     nft_id,
        //     owner,
        //     amount: balance.value(),
        // });
        id.delete();
        let coin_balance = coin::from_balance(balance, ctx);
        transfer::public_transfer(coin_balance, sender);
    }

    #[allow(lint(self_transfer))]
    public fun accept_bid<T: key + store>(market_place_bidding: &mut BadaMarketPlaceBidding, bid_id: ID, item: T, ctx: &mut TxContext){
        assert!(dof::exists_(&market_place_bidding.id, bid_id), 0);
        let bid: BadaMarketPlaceItemBid = dof::remove(&mut market_place_bidding.id, bid_id);
        let item_id = object::id(&item);

        let item_type_name = type_name::get<T>();
        assert!(item_id == bid.nft_id, 0);
        let sender = ctx.sender();
        let BadaMarketPlaceItemBid {id, item_type, nft_id, owner, mut balance} = bid;
        id.delete();
        transfer::public_transfer(item, sender);
        let coin_value = balance.value();
        let mut coin_balance = coin::from_balance(balance, ctx);
        let royalty = coin::split(&mut coin_balance,calculate_percent_amount(coin_value, market_place_bidding.royalties), ctx);
        transfer::public_transfer( royalty, market_place_bidding.beneficiary);
        transfer::public_transfer(coin_balance, sender);

        // event::emit(BadaMarketPlaceItemBidAcceptedEvent {
        //     bid_id,
        //     item_type: *item_type_name.borrow_string(),
        //     nft_id,
        //     seller: owner,
        //     buyer: sender,
        //     price: coin_value,
        //     commission: calculate_percent_amount(coin_value, market_place_bidding.royalties),
        //     beneficiary: market_place_bidding.beneficiary
        // });
    }
}