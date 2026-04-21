import { api, LightningElement } from "lwc";
import { AvailabilityChangedEvent } from "./events";

export default class AvailabilitySelectorCheckbox extends LightningElement {
    @api
    checked = false;

    @api
    hideSymbol = false;
    
    @api
    height = 30;

    get isAvailable() {
        return this.checked === true;
    }

    get isUnavailable() {
        return this.checked === false;
    }

    get isUnknown() {
        return this.checked === null || this.checked === undefined;
    }

    get buttonContent() {
        if (this.hideSymbol) return ' ';
        if (this.isAvailable) return "✓";
        if (this.isUnavailable) return "𐤕";

        return null;
    }

    get containerDivStyles() {
        return `height: ${this.height}px`;
    }

    get customButtonClasses() {
        const classes = ["custom-button"];

        if (this.isAvailable) classes.push("custom-button-available");
        else if (this.isUnavailable) classes.push("custom-button-unavailable");
        else classes.push("custom-button-unknown");

        return classes.join(" ");
    }

    handleOnClick() {
        if (this.isUnknown) this.checked = true;
        else if (this.isAvailable) this.checked = false;
        else this.checked = null;

        this.dispatchEvent(new AvailabilityChangedEvent(this.checked));
    }
}