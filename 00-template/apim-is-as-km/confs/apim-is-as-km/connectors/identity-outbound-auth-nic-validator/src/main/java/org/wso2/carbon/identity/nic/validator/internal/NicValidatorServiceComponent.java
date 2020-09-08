package org.wso2.carbon.identity.nic.validator.internal;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.osgi.framework.BundleContext;
import org.osgi.service.component.ComponentContext;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.wso2.carbon.identity.application.authentication.framework.ApplicationAuthenticator;
import org.wso2.carbon.identity.nic.validator.NicValidator;

@Component(
        name = "org.wso2.carbon.identity.nic.validator.component",
        immediate = true
)
public class NicValidatorServiceComponent {

    private static Log log = LogFactory.getLog(NicValidatorServiceComponent.class);

    @Activate
    protected void activate(ComponentContext ctxt) {
        try {
            BundleContext bundleContext = ctxt.getBundleContext();

            // Register the connector to enforce password change upon expiration.
            bundleContext.registerService(ApplicationAuthenticator.class.getName(),
                    new NicValidator(), null);

            if (log.isDebugEnabled()) {
                log.debug("NicValidator is activated");
            }
        } catch (Throwable e) {
            log.error("Error while activating the NicValidator.", e);
        }
    }

    @Deactivate
    protected void deactivate(ComponentContext ctxt) {
        if (log.isDebugEnabled()) {
            log.debug("NicValidator is deactivated");
        }
    }

}
