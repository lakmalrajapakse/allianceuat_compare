import { ShowToastEvent } from "lightning/platformShowToastEvent";

function showSuccessToast(title, message) {
    showToast("success", title, message);
}

function showErrorToast(title, message) {
    showToast("error", title, message);
}

function showToast(variant, title, message) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    dispatchEvent(evt);
}

function handleTransactionError(title, error) {
    let message = "Unknown error";
    if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
    } else if (typeof error?.body?.message === "string") {
        message = error.body.message;
    } else if (error instanceof Error) {
        console.log(error.stack);
        message = error.message;
    }
    showErrorToast(title, message);
}

function zeroPad(num, places) {
    return String(num).padStart(places, "0");
}

export { handleTransactionError, showErrorToast, showSuccessToast, zeroPad };