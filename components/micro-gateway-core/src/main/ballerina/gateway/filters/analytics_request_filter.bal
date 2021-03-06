// Copyright (c)  WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
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

import ballerina/io;
import ballerina/http;
import ballerina/time;

boolean isAnalyticsEnabled = false;
boolean configsRead = false;

future analyticsConfigReader = start startAnalyticsRelatedFuns();

public type AnalyticsRequestFilter object {

    public function filterRequest(http:Listener listener, http:Request request, http:FilterContext context) returns
                                                                                                                boolean {
        //Filter only is analytics is enabled.
        if (isAnalyticsEnabled) {
            checkOrSetMessageID(context);
            if (request.hasHeader(HOST_HEADER_NAME)) {
                context.attributes[HOSTNAME_PROPERTY] = request.getHeader(HOST_HEADER_NAME);
            } else {
                context.attributes[HOSTNAME_PROPERTY] = "localhost";
            }
            context.attributes[PROTOCOL_PROPERTY] = listener.protocol;
            doFilterRequest(request, context);
        }
        return true;

    }

    public function filterResponse(http:Response response, http:FilterContext context) returns boolean {

        if (isAnalyticsEnabled) {
            boolean filterFailed = check <boolean>context.attributes[FILTER_FAILED];
            if (context.attributes.hasKey(IS_THROTTLE_OUT)) {
                boolean isThrottleOut = check <boolean>context.attributes[IS_THROTTLE_OUT];
                if (isThrottleOut) {
                    ThrottleAnalyticsEventDTO eventDto = populateThrottleAnalyticdDTO(context);
                    eventStream.publish(getEventFromThrottleData(eventDto));
                } else {
                    if (!filterFailed) {
                        doFilterAll(response, context);
                    }
                }
            } else {
                if (!filterFailed) {
                    context.attributes[THROTTLE_LATENCY] = 0;
                    doFilterAll(response, context);
                }
            }
        }
        return true;
    }

};


function doFilterRequest( http:Request request, http:FilterContext context) {
    AnalyticsRequestStream requestEventStream = generateRequestEvent(request, context);
    EventDTO eventDto = generateEventFromRequest(requestEventStream);
    eventStream.publish(eventDto);
}

function doFilterFault(http:FilterContext context, error err) {
    FaultDTO faultDTO = populateFaultAnalyticsDTO(context, err);
    eventStream.publish(getEventFromFaultData(faultDTO));
}

function doFilterResponseData(http:Response response, http:FilterContext context) {
    //Response data publishing
    ResponseDTO responseDto = generateResponseDataEvent(response, context);
    EventDTO event = generateEventFromResponseDTO(responseDto);
    eventStream.publish(event);
}

function doFilterExecutionTimeData(http:Response response, http:FilterContext context) {
    //Execution time data publishing
    ExecutionTimeDTO executionTimeDTO = generateExecutionTimeEvent(context);
    EventDTO eventDTO = generateEventFromExecutionTime(executionTimeDTO);
    eventStream.publish(eventDTO);
}

function doFilterAll(http:Response response, http:FilterContext context) {
    match runtime:getInvocationContext().attributes[ERROR_RESPONSE] {
        () => {
            printDebug(KEY_ANALYTICS_FILTER, "No any faulty analytics events to handle.");
            doFilterResponseData(response, context);
            doFilterExecutionTimeData(response, context);
        }
        any code => {
            printDebug(KEY_ANALYTICS_FILTER, "Error response value present and handling faulty analytics events");
            error err = <error>code;
            doFilterExecutionTimeData(response, context);
            doFilterFault(context, err);
        }
    }
}

function getAnalyticsEnableCOnfig() {
    map vals = getConfigMapValue(ANALYTICS);
    isAnalyticsEnabled = check <boolean>vals[ENABLE];
    configsRead = true;
    printDebug(KEY_UTILS, "Analytics configuration values read");
}


function startAnalyticsRelatedFuns() {
    if (!configsRead) {
        getAnalyticsEnableCOnfig();
        if (isAnalyticsEnabled) {
            printDebug(KEY_ANALYTICS_FILTER, "Analytics is enabled");
            future uploadTask = start timerTask();
            future rotateTask = start rotatingTask();
        } else {
            printDebug(KEY_ANALYTICS_FILTER, "Analytics is disabled");
        }
    }
}