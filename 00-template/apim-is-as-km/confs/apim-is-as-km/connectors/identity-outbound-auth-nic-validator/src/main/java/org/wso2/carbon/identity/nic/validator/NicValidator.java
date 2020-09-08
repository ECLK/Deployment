package org.wso2.carbon.identity.nic.validator;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.carbon.identity.application.authentication.framework.AbstractApplicationAuthenticator;
import org.wso2.carbon.identity.application.authentication.framework.AuthenticatorFlowStatus;
import org.wso2.carbon.identity.application.authentication.framework.LocalApplicationAuthenticator;
import org.wso2.carbon.identity.application.authentication.framework.config.ConfigurationFacade;
import org.wso2.carbon.identity.application.authentication.framework.config.model.StepConfig;
import org.wso2.carbon.identity.application.authentication.framework.context.AuthenticationContext;
import org.wso2.carbon.identity.application.authentication.framework.exception.AuthenticationFailedException;
import org.wso2.carbon.identity.application.authentication.framework.model.AuthenticatedUser;
import org.wso2.carbon.identity.application.authentication.framework.util.FrameworkUtils;
import org.wso2.carbon.identity.core.util.IdentityTenantUtil;
import org.wso2.carbon.user.api.UserRealm;
import org.wso2.carbon.user.api.UserStoreException;
import org.wso2.carbon.user.core.UserStoreManager;
import org.wso2.carbon.user.core.service.RealmService;
import org.wso2.carbon.user.core.util.UserCoreUtil;
import org.wso2.carbon.utils.multitenancy.MultitenantUtils;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class NicValidator extends AbstractApplicationAuthenticator implements LocalApplicationAuthenticator {

    private static final long serialVersionUID = -1370704782069207523L;

    private static final Log log = LogFactory.getLog(NicValidator.class);

    @Override
    public boolean canHandle(HttpServletRequest httpServletRequest) {

        return true;
    }

    @Override
    public String getContextIdentifier(HttpServletRequest request) {

        return request.getParameter(NicValidatorConstants.STATE);
    }

    @Override
    public String getFriendlyName() {

        return NicValidatorConstants.AUTHENTICATOR_FRIENDLY_NAME;
    }

    @Override
    public String getName() {

        return NicValidatorConstants.AUTHENTICATOR_NAME;
    }

    @Override
    public AuthenticatorFlowStatus process(HttpServletRequest request, HttpServletResponse response,
                                           AuthenticationContext context)
            throws AuthenticationFailedException {
        // If the logout request comes, then no need to go through and doing complete the flow.
        if (context.isLogoutRequest()) {
            return AuthenticatorFlowStatus.SUCCESS_COMPLETED;
        }

        if (isAlreadyValidated(context)) {
            updateAuthenticatedUserInStepConfig(context);
            return AuthenticatorFlowStatus.SUCCESS_COMPLETED;
        }

        if (StringUtils.isNotBlank(request.getParameter(NicValidatorConstants.NATIONAL_ID))) {
            try {
                processAuthenticationResponse(request, response, context);
            } catch (Exception e) {
                context.setRetrying(true);
                context.setCurrentAuthenticator(getName());
                return initiateAuthRequest(response, context, e.getMessage());
            }
            return AuthenticatorFlowStatus.SUCCESS_COMPLETED;
        } else {
            return initiateAuthRequest(response, context, null);
        }
    }

    /**
     * This will prompt the user to enter the NIC.
     *
     * @param response the response
     * @param context  the authentication context
     */
    private AuthenticatorFlowStatus initiateAuthRequest(HttpServletResponse response, AuthenticationContext context,
                                                        String errorMessage)
            throws AuthenticationFailedException {
        // Find the authenticated user.
        AuthenticatedUser authenticatedUser = getUser(context);

        if (authenticatedUser == null) {
            throw new AuthenticationFailedException("Authentication failed!. " +
                    "Cannot proceed further without identifying the user");
        }

        String tenantDomain = authenticatedUser.getTenantDomain();
        String username = authenticatedUser.getAuthenticatedSubjectIdentifier();
        String tenantAwareUsername = MultitenantUtils.getTenantAwareUsername(username);

        try {
            // Creating the URL to which the user will be redirected
            String redirectPage = ConfigurationFacade.getInstance().getAuthenticationEndpointURL()
                    .replace(NicValidatorConstants.LOGIN_STANDARD_PAGE,
                            NicValidatorConstants.NIC_VALIDATION_PAGE);
            String queryParams = FrameworkUtils.getQueryStringWithFrameworkContextId(context.getQueryParams(),
                    context.getCallerSessionKey(), context.getContextIdentifier());
            String retryParam = "";
            if (context.isRetrying()) {
                retryParam = "&authFailure=true&authFailureMsg=" + errorMessage;
            }
            String fullyQualifiedUsername = UserCoreUtil.addTenantDomainToEntry(tenantAwareUsername,
                    tenantDomain);
            String encodedUrl = (redirectPage + ("?" + queryParams + "&username=" + fullyQualifiedUsername))
                    + "&authenticators=" + getName() + ":" + NicValidatorConstants.AUTHENTICATOR_TYPE
                    + retryParam;

            response.sendRedirect(encodedUrl);
        } catch (IOException e) {
            throw new AuthenticationFailedException(e.getMessage(), e);
        }
        context.setCurrentAuthenticator(getName());
        return AuthenticatorFlowStatus.INCOMPLETE;
    }

    @Override
    protected void processAuthenticationResponse(HttpServletRequest request, HttpServletResponse response,
                                                 AuthenticationContext context) throws AuthenticationFailedException {

        AuthenticatedUser authenticatedUser = getUser(context);
        String username = authenticatedUser.getAuthenticatedSubjectIdentifier();
        String tenantAwareUsername = MultitenantUtils.getTenantAwareUsername(username);

        String nationalId = request.getParameter(NicValidatorConstants.NATIONAL_ID);

        // Checking current, new and repeat new passwords
        if (StringUtils.isBlank(nationalId)) {
            throw new AuthenticationFailedException("NIC cannot be empty.");
        }

        // Fetching user store manager
        UserStoreManager userStoreManager = getUserStoreManager(authenticatedUser);

        String nationalIdClaimValue;
        try {
            String[] claimURIs = new String[]{NicValidatorConstants.NATIONAL_ID_CLAIM};
            Map<String, String> claimValueMap =
                    userStoreManager.getUserClaimValues(tenantAwareUsername, claimURIs, null);
            nationalIdClaimValue = claimValueMap.get(NicValidatorConstants.NATIONAL_ID_CLAIM);

            if (StringUtils.equalsIgnoreCase(nationalId, nationalIdClaimValue)) {
                claimValueMap = new HashMap<>();
                claimValueMap.put(NicValidatorConstants.NIC_VALIDATED_CLAIM, "true");
                userStoreManager.setUserClaimValues(username, claimValueMap, null);

                // Authentication is now completed in this step. Update the authenticated user information.
                updateAuthenticatedUserInStepConfig(context);
            } else {
                throw new AuthenticationFailedException("The provided NIC is incorrect.");
            }

        } catch (UserStoreException e) {
            throw new AuthenticationFailedException("Error occurred while processing claims.", e);
        }

    }

    private UserStoreManager getUserStoreManager(AuthenticatedUser authenticatedUser) throws AuthenticationFailedException {

        UserStoreManager userStoreManager;
        try {
            String tenantDomain = authenticatedUser.getTenantDomain();
            int tenantId = IdentityTenantUtil.getTenantId(tenantDomain);
            RealmService realmService = IdentityTenantUtil.getRealmService();
            UserRealm userRealm = realmService.getTenantUserRealm(tenantId);
            userStoreManager = (UserStoreManager) userRealm.getUserStoreManager();
        } catch (UserStoreException e) {
            throw new AuthenticationFailedException("Error occurred while loading user realm or user store manager.",
                    e);
        }
        return userStoreManager;
    }

    private AuthenticatedUser getUser(AuthenticationContext context) {

        StepConfig stepConfig = context.getSequenceConfig().getStepMap().get(context.getCurrentStep() - 1);
        return stepConfig.getAuthenticatedUser();
    }

    private void updateAuthenticatedUserInStepConfig(AuthenticationContext context) {

        AuthenticatedUser authenticatedUser = getUser(context);
        StepConfig stepConfig = context.getSequenceConfig().getStepMap().get(context.getCurrentStep());
        stepConfig.setAuthenticatedUser(authenticatedUser);
        context.setSubject(authenticatedUser);
    }

    private boolean isAlreadyValidated(AuthenticationContext context) throws AuthenticationFailedException {

        AuthenticatedUser authenticatedUser = getUser(context);
        String username = authenticatedUser.getAuthenticatedSubjectIdentifier();
        String tenantAwareUsername = MultitenantUtils.getTenantAwareUsername(username);
        // Fetching user store manager
        UserStoreManager userStoreManager = getUserStoreManager(authenticatedUser);

        String isNationalIdValidatedClaimValue;
        try {
            String[] claimURIs = new String[]{NicValidatorConstants.NIC_VALIDATED_CLAIM};
            Map<String, String> claimValueMap =
                    userStoreManager.getUserClaimValues(tenantAwareUsername, claimURIs, null);
            isNationalIdValidatedClaimValue = claimValueMap.get(NicValidatorConstants.NIC_VALIDATED_CLAIM);

            return Boolean.parseBoolean(isNationalIdValidatedClaimValue);

        } catch (UserStoreException e) {
            throw new AuthenticationFailedException("Error occurred while processing claims.", e);
        }

    }
}
