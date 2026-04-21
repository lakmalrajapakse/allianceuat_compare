public class SMSSender {
    public static void sendSMS(String to, String body, Id messageId) {
        SMSSenderService senderService = new SMSSenderService();
        senderService.sendSMS(to, body, messageId);
    }
}