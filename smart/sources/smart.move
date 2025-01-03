/// Module: smart
module smart::smart;
use sui::event;
public struct MarketPlace has key{
    id: UID,
}
public struct MarketPlaceCreated has copy, drop{
    object_id : ID,
}

fun init(ctx: &mut TxContext){
    let marketplace : MarketPlace = MarketPlace{
        id: object::new(ctx),
    };

    event::emit(MarketPlaceCreated { 
        object_id: object::id(&marketplace),
    });
    transfer::share_object(marketplace);
}