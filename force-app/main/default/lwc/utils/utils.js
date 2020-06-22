import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Utils {

    static showToast = (firingComponent, toastTitle, toastBody, variant) => {
        firingComponent.dispatchEvent(new ShowToastEvent({
            title : toastTitle,
            message : toastBody,
            variant : variant
        }));
    }

    static showModal = (firingComponent, header, content) => {
        firingComponent.dispatchEvent(new CustomEvent('showmodal', {
            detail : {
                header : header,
                content : content
            },
            bubbles : true,
            composed : true
        }));
    }

}