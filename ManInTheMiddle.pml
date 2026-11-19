/* model.pml – Handshake with loss and maximum retries */

// 1) Message types
mtype = { SYN, SYN_ACK, ACK };

// 2) Variables
byte ack_sent = 0;
byte retries = 0;
#define MAX_RETRY 3

// 3) Channels
chan client_to_medium = [1] of { mtype };
chan medium_to_server = [1] of { mtype };
chan server_to_client = [1] of { mtype };

// 4) Medium (unreliable channel)
proctype Medium() {
    mtype message;
    do
    :: client_to_medium?message ->
        if
        :: medium_to_server!message       // deliver the message correctly
        :: skip                           // drop the packet
        fi
    od
}

// 5) Client with retry limit
proctype Client() {
    printf("Client: sending SYN\n");
    client_to_medium!SYN;

    do
    :: server_to_client?SYN_ACK ->
        printf("Client: received SYN_ACK\n");
        break
    :: timeout ->
        retries++;
        printf("Client: timeout, retransmitting SYN (attempt %d)\n", retries);
        client_to_medium!SYN;
        if
        :: retries >= MAX_RETRY -> break
        :: else -> skip
        fi
    od;

    if
    :: retries < MAX_RETRY ->
        printf("Client: sending ACK, handshake completed\n");
        ack_sent = 1;
        server_to_client!ACK;
    :: else ->
        printf("Client: handshake failed due to too many attempts\n");
    fi
}

// 6) Server
proctype Server() {
    printf("Server: waiting for SYN\n");
    medium_to_server?SYN;
    printf("Server: received SYN\n");

    printf("Server: sending SYN_ACK\n");
    server_to_client!SYN_ACK;

    printf("Server: waiting for ACK\n");
    server_to_client?ACK;
    printf("Server: received ACK, handshake completed\n");
}

// 7) Init
init {
    run Medium();
    run Client();
    run Server();
}

// 8) LTL property
ltl eventual_ack { <> ack_sent }