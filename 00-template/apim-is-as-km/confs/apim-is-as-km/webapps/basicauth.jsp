<%--
  ~ Copyright (c) 2014, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ WSO2 Inc. licenses this file to you under the Apache License,
  ~ Version 2.0 (the "License"); you may not use this file except
  ~ in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  --%>

<%@ page import="org.apache.cxf.jaxrs.client.JAXRSClientFactory" %>
<%@ page import="org.apache.cxf.jaxrs.provider.json.JSONProvider" %>
<%@ page import="org.apache.http.HttpStatus" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.client.SelfUserRegistrationResource" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.AuthenticationEndpointUtil" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.bean.ResendCodeRequestDTO" %>
<%@ page import="org.wso2.carbon.identity.application.authentication.endpoint.util.bean.UserDTO" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="javax.ws.rs.core.Response" %>
<%@ page import="static org.wso2.carbon.identity.core.util.IdentityUtil.isSelfSignUpEPAvailable" %>
<%@ page import="static org.wso2.carbon.identity.core.util.IdentityUtil.isRecoveryEPAvailable" %>
<%@ page import="static org.wso2.carbon.identity.core.util.IdentityUtil.getServerURL" %>

<jsp:directive.include file="init-loginform-action-url.jsp"/>


<script>
        function submitCredentials (e) {
            e.preventDefault();
            var resp = $("[name='g-recaptcha-response']")[0].value;
            var error_msg = $("#error-msg");
            if (resp.trim() == '') {
                error_msg.text("<%=AuthenticationEndpointUtil.i18n(resourceBundle,"please.select.recaptcha")%>");
                error_msg.show();
                alert("Please select reCaptcha");
                $("html, body").animate({scrollTop: error_msg.offset().top}, 'slow');
                return false;
            }
            var userName = document.getElementById("username");
            userName.value = userName.value.trim();
            if(userName.value){
                document.getElementById("loginForm").submit();
            }
        }
</script>

<%!
    private static final String JAVAX_SERVLET_FORWARD_REQUEST_URI = "javax.servlet.forward.request_uri";
    private static final String JAVAX_SERVLET_FORWARD_QUERY_STRING = "javax.servlet.forward.query_string";
    private static final String UTF_8 = "UTF-8";
%>
<%
    String resendUsername = request.getParameter("resend_username");
    if (StringUtils.isNotBlank(resendUsername)) {

        String url = config.getServletContext().getInitParameter(Constants.ACCOUNT_RECOVERY_REST_ENDPOINT_URL);

        ResendCodeRequestDTO selfRegistrationRequest = new ResendCodeRequestDTO();
        UserDTO userDTO = AuthenticationEndpointUtil.getUser(resendUsername);
        selfRegistrationRequest.setUser(userDTO);
        url = url.replace("tenant-domain", userDTO.getTenantDomain());

        List<JSONProvider> providers = new ArrayList<JSONProvider>();
        JSONProvider jsonProvider = new JSONProvider();
        jsonProvider.setDropRootElement(true);
        jsonProvider.setIgnoreNamespaces(true);
        jsonProvider.setValidateOutput(true);
        jsonProvider.setSupportUnwrapped(true);
        providers.add(jsonProvider);

        SelfUserRegistrationResource selfUserRegistrationResource = JAXRSClientFactory
                .create(url, SelfUserRegistrationResource.class, providers);
        Response selfRegistrationResponse = selfUserRegistrationResource.regenerateCode(selfRegistrationRequest);
        if (selfRegistrationResponse != null &&  selfRegistrationResponse.getStatus() == HttpStatus.SC_CREATED) {
%>
<div class="alert alert-info">
    <%=AuthenticationEndpointUtil.i18n(resourceBundle,Constants.ACCOUNT_RESEND_SUCCESS_RESOURCE)%>
</div>
<%
} else {
%>
<div class="alert alert-danger">
    <%=AuthenticationEndpointUtil.i18n(resourceBundle,Constants.ACCOUNT_RESEND_FAIL_RESOURCE)%>
</div>
<%
        }
    }
%>

<form action="<%=loginFormActionURL%>" method="post" id="loginForm">

    <%
        if (loginFormActionURL.equals(samlssoURL) || loginFormActionURL.equals(oauth2AuthorizeURL)) {
    %>
    <input id="tocommonauth" name="tocommonauth" type="hidden" value="true">
    <%
        }
    %>

    <% if (Boolean.parseBoolean(loginFailed)) { %>
    <div class="alert alert-danger" id="error-msg"><%= AuthenticationEndpointUtil.i18n(resourceBundle, errorMessage) %>
    </div>
    <%}else if((Boolean.TRUE.toString()).equals(request.getParameter("authz_failure"))){%>
    <div class="alert alert-danger" id="error-msg">
        <%=AuthenticationEndpointUtil.i18n(resourceBundle, "unauthorized.to.login")%>
    </div>
    <%}%>

    <% if (!isIdentifierFirstLogin(inputType)) { %>
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
        <label for="username"><%=AuthenticationEndpointUtil.i18n(resourceBundle, "username")%></label>
        <input id="username" name="username" type="text" class="form-control" tabindex="0" placeholder="" required>
    </div>
    <% } else {%>
        <input id="username" name="username" type="hidden" value="<%=username%>">
    <% }%>
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
        <label for="password"><%=AuthenticationEndpointUtil.i18n(resourceBundle, "password")%></label>
        <input id="password" name="password" type="password" class="form-control" placeholder="" autocomplete="off">
    </div>
    <!-- <%
        if (reCaptchaEnabled) {
    %> -->
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
        <div class="g-recaptcha"
             data-sitekey="6LfD4-MUAAAAAIkumMqIWyPLNOWd3tmyyOwsztNe">
        </div>
    </div>
    <!-- <%
        }
    %> -->
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
        
    </div>
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12">
        <input type="hidden" name="sessionDataKey" value='<%=Encode.forHtmlAttribute
            (request.getParameter("sessionDataKey"))%>'/>
    </div>
    <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
        <div class="form-actions">
            <button
                    class="wr-btn grey-bg col-xs-12 col-md-12 col-lg-12 uppercase font-extra-large margin-bottom-double"
                    type="submit" onclick="submitCredentials(event)">
                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "login")%>
            </button>
        </div>
    </div>
        
    <% if (Boolean.parseBoolean(loginFailed) && errorCode.equals(IdentityCoreConstants.USER_ACCOUNT_NOT_CONFIRMED_ERROR_CODE) && request.getParameter("resend_username") == null) { %>
        <div class="col-xs-12 col-sm-12 col-md-12 col-lg-12 form-group">
            <div class="form-actions">
                <%=AuthenticationEndpointUtil.i18n(resourceBundle, "no.confirmation.mail")%>
                <a id="registerLink"
                   href="login.do?resend_username=<%=Encode.forHtml(request.getParameter("failedUsername"))%>&<%=AuthenticationEndpointUtil.cleanErrorMessages(request.getQueryString())%>">
                    <%=AuthenticationEndpointUtil.i18n(resourceBundle, "resend.mail")%>
                </a>
            </div>
        </div>
        <%}%>
    </div>

    <div class="clearfix"></div>
    <%!
    private String getRecoverPasswordUrl(String identityMgtEndpointContext, String urlEncodedURL) {
        return identityMgtEndpointContext + "/recoverpassword.do?callback=" + Encode.forHtmlAttribute(urlEncodedURL);
    }
    private String getRecoverUsernameUrl(String identityMgtEndpointContext, String urlEncodedURL) {
        return identityMgtEndpointContext + "/recoverusername.do?callback=" + Encode.forHtmlAttribute(urlEncodedURL);
    }
    private String getRegistrationUrl(String identityMgtEndpointContext, String urlEncodedURL) {
        return identityMgtEndpointContext + "/register.do?callback=" + Encode.forHtmlAttribute(urlEncodedURL);
    }
    %>
</form>
