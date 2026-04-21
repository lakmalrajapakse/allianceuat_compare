/**
 * MassMessageManagerExtension is a controller extension used to handle the selected records
 * from a list view or related list in Salesforce.
 */
public class MassMessageManagerExtension {

    // String to store the concatenated IDs of selected records.
    public String selectedRecordIds { get; private set; }

    /**
     * Constructor for the MassMessageManagerExtension class.
     * It retrieves the selected records from the StandardSetController,
     * extracts their IDs, and joins them into a single string.
     *
     * @param controller The StandardSetController provided by Salesforce that
     *                   represents the context of the list or related list view.
     */
    public MassMessageManagerExtension(ApexPages.StandardSetController controller) {
        // Retrieve the selected records as a list of SObjects.
        List<SObject> selectedRecords = controller.getSelected();

        // Initialize a list to store the IDs of the selected records.
        List<Id> selectedIds = new List<Id>();

        // Loop over each selected record to extract its ID.
        for (SObject selectedRecord : selectedRecords) {
            // Add the ID of the current record to the list of selected IDs.
            selectedIds.add((Id)selectedRecord.get('Id'));
        }

        // If there are selected IDs, join them into a comma-separated string.
        if (!selectedIds.isEmpty()) {
            selectedRecordIds = String.join(selectedIds, ',');
        }
    }
}