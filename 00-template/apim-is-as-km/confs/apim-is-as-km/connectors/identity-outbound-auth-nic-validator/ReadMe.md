## NIC validator
This validator can be used to validate the NIC of a user in the initial login.

#### Setup
1. Add the `org.wso2.carbon.extension.identity.authenticator.nic.validator-1.0.0.jar` to the dropins directory `/repository/components/dropins`
2. Add `nic-validate.jsp` to `/repository/deployment/server/webapps/authenticationendpoint`
3. Add the following two local claims.
    ```
    http://wso2.org/claims/nationalId
    http://wso2.org/claims/identity/nicValidated
    ```
4. For the validator to work properly, make sure the relvant users have their nic stored in the  `http://wso2.org/claims/nationalId` claim.