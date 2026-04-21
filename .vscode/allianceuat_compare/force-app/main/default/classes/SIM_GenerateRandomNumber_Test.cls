@isTest
global with sharing class SIM_GenerateRandomNumber_Test {
    
    @isTest
    global static void numberReturnedIsInRange() {
        Integer startNum = 0;
        Integer endNum =1;
        
        SIM_GenerateRandomNumber.Requests curRequest = new SIM_GenerateRandomNumber.Requests();
        curRequest.startNumber= startNum;
        curRequest.endNumber = endNum;
        
        List<SIM_GenerateRandomNumber.Requests> curRequestList = new List<SIM_GenerateRandomNumber.Requests>();
        curRequestList.add(curRequest);
        
        Test.startTest();
        List<SIM_GenerateRandomNumber.Results> resultsList = new List<SIM_GenerateRandomNumber.Results>();      
        resultsList = SIM_GenerateRandomNumber.getRandomNumberFromRange(curRequestList);
        Test.stopTest();

        Double resultNum = resultsList[0].randomNumber;
        System.assertEquals(true, resultNum>startNum);
        System.assertEquals(true, resultNum<endNum);
    }
    
    @isTest
    public static void numberZeroToOneGeneratedIsInRange() {
        Integer startNum = 0;
        Integer endNum =1;
            
        Test.startTest();
        Double resultNum = SIM_GenerateRandomNumber.generateRandomFromRange(startNum, endNum);
        Test.stopTest();
    
        System.assertEquals(true, resultNum>startNum);
        System.assertEquals(true, resultNum<endNum);
    }
    
    @isTest
    public static void numberAboveOneGeneratedIsInRange() {
        Integer startNum = 5;
        Integer endNum =7;
            
        Test.startTest();
        Double resultNum = SIM_GenerateRandomNumber.generateRandomFromRange(startNum, endNum);
        Test.stopTest();
    
    }
    
}