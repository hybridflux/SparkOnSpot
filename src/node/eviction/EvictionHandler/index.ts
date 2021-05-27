import { AzureFunction, Context, HttpRequest } from "@azure/functions"
import { ComputeManagementClient } from "@azure/arm-compute"
import * as msRestNodeAuth from "@azure/ms-rest-nodeauth"

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
    context.log.info('eviction notice received from ' + JSON.stringify( req.body ) );

    // TODO: Validate values
    try {
        RestartVM( context.req.body.name, context.req.body.rgname );
    
        context.res = {
            status: 202,
            body: context.req.body
        };
    }
    catch( err ) {    
        context.res = {
            status: 500,
            // TODO: Don't leave the full error here
            body: err
        };
    }

    function RestartVM( vmName:string, rgName: string ) {
        const clientId =  process.env["CLIENT_ID"];
        const secret = process.env["SECRET"];
        const tenantId = process.env["TENANT_ID"];
        const subscriptionId = process.env["SUBSCRIPTION_ID"];

        console.log( "env set up for subscription: " + subscriptionId);
        // Get Auth Token
        msRestNodeAuth.loginWithServicePrincipalSecretWithAuthResponse(clientId, secret, tenantId).then((authresponse) => {
            // API Call to re-start the VM 
            var creds = authresponse.credentials;
            const client = new ComputeManagementClient(creds, subscriptionId);
            client.virtualMachines.start(rgName, vmName).then((result) => {
                console.log("The result is:");
                console.log(result);
            });
        }).catch((error) => {
            console.error(error);
            throw error;
        });
        return;
    };
};

export default httpTrigger;