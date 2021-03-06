// Copyright (c)  WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file   except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/auth;
import ballerina/config;
import ballerina/runtime;
import ballerina/system;
import ballerina/time;
import ballerina/io;
import ballerina/reflect;
import wso2/gateway;

// Extension filter used to send custom error messages and to do customizations.
@Description {value:"Representation of the Subscription filter"}
@Field {value:"filterRequest: request filter method which attempts to validate the subscriptions"}
public type ExtensionFilter object {

    @Description {value:"filterRequest: Request filter function"}
    public function filterRequest (http:Listener listener, http:Request request, http:FilterContext context) returns
                                                                                                                boolean {
        return true;
    }

    public function filterResponse(http:Response response, http:FilterContext context) returns boolean {
        match <boolean> context.attributes[gateway:FILTER_FAILED] {
            boolean failed => {
                if (failed) {
                    int statusCode = check <int>context.attributes[gateway:HTTP_STATUS_CODE];
                    if(statusCode == gateway:UNAUTHORIZED) {
                        setAuthenticationErrorResponse(response, context );
                    } else if (statusCode ==  gateway:FORBIDDEN) {
                        setAuthorizationErrorResponse(response, context );
                    } else if (statusCode ==  gateway:THROTTLED_OUT){
                        setThrottleFailureResponse(response, context );
                    } else {
                        setGenericErrorResponse(response, context );
                    }

                    return true;
                    //return gateway:createFilterResult(false, statusCode, errorMessage);
                }
            } error err => {
            //Nothing to handle
            return true;
            }
        }

        return true;
    }

};

@Description {value:"This method can be used to send custom error message in an authentication failure"}
function setAuthenticationErrorResponse(http:Response response, http:FilterContext context) {
    //Un comment the following code and set the proper error messages

    //int statusCode = check <int>context.attributes[gateway:HTTP_STATUS_CODE];
    //string errorDescription = <string>context.attributes[gateway:ERROR_DESCRIPTION];
    //string errorMesssage = <string>context.attributes[gateway:ERROR_MESSAGE];
    //int errorCode = check <int>context.attributes[gateway:ERROR_CODE];
    //response.statusCode = statusCode;
    //response.setContentType(gateway:APPLICATION_JSON);
    //json payload = {fault : {
    //    code : errorCode,
    //    message : errorMesssage,
    //    description : errorDescription
    //}};
    //response.setJsonPayload(payload);
}

@Description {value:"This method can be used to send custom error message in an authorization failure"}
function setAuthorizationErrorResponse(http:Response response, http:FilterContext context) {

}

@Description {value:"This method can be used to send custom error message when message throttled out"}
function setThrottleFailureResponse(http:Response response, http:FilterContext context) {

}

@Description {value:"This method can be used to send custom general error message "}
function setGenericErrorResponse(http:Response response, http:FilterContext context) {

}

