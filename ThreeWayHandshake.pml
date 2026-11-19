/* ThreeWayHandshake.pml – Three-way handshake with inline sequencing and completion checker */

// Message types
mtype = { SYN, SYN_ACK, ACK };

// Two channels to simulate the network (buffer size 1 for simplicity)
chan client_to_server = [1] of { mtype, byte, byte };
chan server_to_client = [1] of { mtype, byte, byte };

// Flags to verify that both sides have completed the handshake
bool client_completed = false;
bool server_completed = false;

// Client process
proctype Client() {
    byte client_seq = 100;           // initial client sequence number
    byte ack_num;
    mtype msg;
    byte received_seq;
    byte received_ack;

    printf("Client: sending SYN(seq=%d)\n", client_seq);
    client_to_server!SYN, client_seq, 0;     // send SYN

    // wait for SYN-ACK
    server_to_client?msg, received_seq, received_ack;
    assert(msg == SYN_ACK);
    assert(received_ack == client_seq + 1);
    printf("Client: received SYN_ACK(seq=%d, ack=%d)\n", received_seq, received_ack);

    // send ACK
    ack_num = received_seq + 1;
    printf("Client: sending ACK(seq=%d, ack=%d)\n", client_seq + 1, ack_num);
    client_to_server!ACK, client_seq + 1, ack_num;

    client_completed = true;
}

// Server process
proctype Server() {
    mtype msg;
    byte client_seq;
    byte client_ack;
    byte server_seq = 200;           // initial server sequence number
    byte ack_num;

    // receive SYN
    client_to_server?msg, client_seq, client_ack;
    assert(msg == SYN);
    printf("Server: received SYN(seq=%d)\n", client_seq);

    // reply with SYN-ACK
    ack_num = client_seq + 1;
    printf("Server: sending SYN_ACK(seq=%d, ack=%d)\n", server_seq, ack_num);
    server_to_client!SYN_ACK, server_seq, ack_num;

    // receive final ACK
    client_to_server?msg, client_seq, client_ack;
    assert(msg == ACK);
    assert(client_ack == server_seq + 1);
    printf("Server: received ACK(seq=%d, ack=%d)\n", client_seq, client_ack);

    server_completed = true;
}

// Checker to ensure both sides complete without deadlock
proctype Checker() {
    do
    :: client_completed && server_completed -> break
    od;
    printf(">>> Three-way handshake successful!\n");
    assert(client_completed);
    assert(server_completed);
}

// Initialization
init {
    run Client();
    run Server();
    run Checker();
}