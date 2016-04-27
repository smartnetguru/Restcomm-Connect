/*
 * TeleStax, Open Source Cloud Communications
 * Copyright 2016, Telestax Inc and individual contributors
 * by the @authors tag.
 *
 * This program is free software: you can redistribute it and/or modify
 * under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */

package org.mobicents.servlet.restcomm.identity.mocks;

import org.apache.commons.lang.StringUtils;
import org.mobicents.servlet.restcomm.configuration.sets.IdentityConfigurationSet;

/**
 * @author Orestis Tsakiridis
 */
public class IdentityConfigurationSetMock implements IdentityConfigurationSet {

    String authServerUrl;
    String realm = "restcomm";
    String realmKey = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrVrCuTtArbgaZzL1hvh0xtL5mc7o0NqPVnYXkLvgcwiC3BjLGw1tGEGoJaXDuSaRllobm53JBhjx33UNv";

    public IdentityConfigurationSetMock() {
    }

    public void setAuthServerUrl(String authServerUrl) {
        this.authServerUrl = authServerUrl;
    }
    @Override
    public String getRealm() {
        return realm;
    }

    @Override
    public String getRealmkey() {
        return realmKey;
    }

    @Override
    public boolean externalAuthEnabled() {
        if (StringUtils.isEmpty(authServerUrl))
            return false;
        return true;
    }

    @Override
    public String getAuthServerUrl() {
        return authServerUrl;
    }
}