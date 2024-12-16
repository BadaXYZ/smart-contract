module bada::nft{
    use std::string::{Self, String};
    use sui::url::{Self, Url};
    use sui::event;

    public struct NFT has key, store {
        id: UID,                 
        name: String,            
        description: String,     
        creator: address,        
        owner: address,          
        url: Url,
    }

    public struct NFTMinted has copy, drop {
        object_id: ID,         
        creator: address,       
        name: String,           
    }

    public fun name(nft: &NFT): &String {
        &nft.name
    }

    public fun description(nft: &NFT): &String {
        &nft.description
    }

    public fun url(nft: &NFT): &Url {
        &nft.url
    }

    public fun creator(nft: &NFT): &address {
        &nft.creator
    }

    public fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,          
        ctx: &mut TxContext
    ) : NFT{
        let sender = ctx.sender();

        let nft =NFT{
            id: object::new(ctx),      
            name: string::utf8(name),         
            description: string::utf8(description),   
            creator: sender,     
            owner: sender,   
            url: url::new_unsafe_from_bytes(url),
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        // transfer::public_transfer(nft, sender);
        nft
    }

    public fun burn(
        nft: NFT,
        _: &mut TxContext
    ) {
        let NFT { id, name: _, description: _,creator: _, owner: _, url: _ ,} = nft;
        id.delete();
    }
}