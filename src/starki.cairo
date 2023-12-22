#[starknet::interface]
trait IStarki<TContractState> {
    fn inscribe(ref self: TContractState, user_data: Array::<felt252>) -> u8;
}

#[starknet::contract]
mod Starki {
    use core::box::BoxTrait;
    use core::starknet::event::EventEmitter;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::ClassHash;
    use starknet::ContractAddress;
    use starknet::get_block_info;
    use starknet::get_contract_address;
    use starknet::{get_caller_address, get_tx_info};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    /// Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        // inscaribe: LegacyMap::<ContractAddress, Array<u128>>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        InscribeEvent: InscribeEvent,
    }

    #[derive(Drop, starknet::Event)]
    struct InscribeEvent {
        #[key]
        user: ContractAddress,
        #[key]
        block_number: u64,
        #[key]
        block_time: u64,
        data: Array<felt252>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
        self.ownable.initializer(caller);
    }

    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // This function can only be called by the owner
            self.ownable.assert_only_owner();

            // Replace the class hash upgrading the contract
            self.upgradeable._upgrade(new_class_hash);
        }
    }


    #[external(v0)]
    impl Starki of super::IStarki<ContractState> {
        fn inscribe(ref self: ContractState, user_data: Array::<felt252>) -> u8 {
            let caller = get_caller_address();
            self
                .emit(
                    InscribeEvent {
                        user: caller,
                        block_time: get_block_info().unbox().block_timestamp,
                        block_number: get_block_info().unbox().block_number,
                        data: user_data,
                    }
                );
            return 1;
        }
    }
}
