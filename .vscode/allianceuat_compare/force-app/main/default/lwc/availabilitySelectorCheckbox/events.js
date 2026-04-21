export class AvailabilityChangedEvent extends CustomEvent {
    constructor(available) {
        super("availabilitychanged", { detail: { available } });
    }
}