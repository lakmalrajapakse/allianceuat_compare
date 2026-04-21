/**
 * MobileMessageMassSMSController
 * This controller class is used within the Salesforce platform to manage the sending of mass SMS messages to a list of contacts.
 * It provides functionality to interact with a user interface that allows a Salesforce user to select multiple contacts,
 * compose a message, and then send it as an SMS to all selected contacts.
 *
 * The class also manages the state of a modal dialog in the user interface, which is used for composing the message.
 * The modal can be opened or closed, and it holds the message content that will be sent.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Created on: [Creation Date]
 * Last modified on: 15 Jan 2024 at 4:06:21 pm AEST (Melbourne, Australia)
 *
 * Usage:
 * - The Salesforce user selects contacts from a list view and triggers the mass SMS functionality.
 * - The user composes a message in a modal dialog, which is controlled by this class.
 * - When ready, the user sends the message to all selected contacts.
 */
public class MobileMessageMassSMSController {

    // Holds the list of contacts selected by the user for sending SMS.
    public List<Contact> contacts { get; private set; }
    
    // StandardSetController reference to manage the selection and pagination of records in the list view.
    private final ApexPages.StandardSetController controller;

    // Constructor: Initializes the controller and retrieves the selected contacts.
    public MobileMessageMassSMSController(ApexPages.StandardSetController stdSetController) {
        // Assign the passed StandardSetController to the local controller variable.
        this.controller = stdSetController;
        // Retrieve all selected records (contacts) using the StandardSetController.
        contacts = (List<Contact>) stdSetController.getSelected();
    }
  
    // Flag to track if the modal dialog is open or closed in the UI.
    public Boolean isModalOpen { get; set; }
    
    // The message content that will be sent as an SMS to the selected contacts.
    public String message { get; set; }
  
    // Method to close the modal dialog in the UI.
    public void closeModal() {
        isModalOpen = false;
    }
  
    // Method to open the modal dialog in the UI and prepare for message composition.
    public void openModal() {
        // Additional logic can be added here to prepare the modal for opening, such as setting default message content.
        isModalOpen = true;
    }
}