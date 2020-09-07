package org.wso2.carbon.identity.nic.validator;

/**
 * Authenticator constants
 */
public class NicValidatorConstants {

    public static final String AUTHENTICATOR_NAME = "nic-validator";
    public static final String AUTHENTICATOR_FRIENDLY_NAME = "NIC Validator";
    public static final String AUTHENTICATOR_TYPE = "LOCAL";
    public static final String STATE = "state";
    public static final String NATIONAL_ID = "nationalId";
    public static final String NIC_VALIDATION_PAGE = "nic-validate.jsp";
    public static final String NATIONAL_ID_CLAIM = "http://wso2.org/claims/nationalId";
    public static final String NIC_VALIDATED_CLAIM = "http://wso2.org/claims/identity/nicValidated";
    public static final String LOGIN_STANDARD_PAGE = "login.do";

    private NicValidatorConstants() { }
}
