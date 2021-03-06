/**
 * OverlayNetworkC tests the setup and functionality of an overlay
   network using networks which utilize the protocols CTP, AODV, and
   sequence number controlled flooding. The full test TOSSIM script is 
   runnable at testCombined.py. This application is a deep modification
   to Philip Levis's"OverlayNetworkC, originally designed to test only a CTP
   network
 *
 * @author Jacob Strauss, Adam Skonieczny
 * @version 1.0, 07-22-2016
 */

#include <Timer.h>
#include "OverlayNetwork.h"
#include "CtpDebugMsg.h"
#include <stdlib.h>

module OverlayNetworkC {
  provides interface GetProt;
  uses interface Boot;
  uses interface Receive as ReceiveAODV;
  uses interface Receive as ReceiveCTP;
  uses interface Receive as ReceiveFlood;
  uses interface Receive as ReceiveRout;
  uses interface Receive as ReceivePingReq; //used for overlap pings
  uses interface Receive as ReceivePingRep; //used for overlap pings
  uses interface Receive as ReceiveUniversal; 
  uses interface SplitControl as SplitControlAODV;
  uses interface SplitControl as RadioControl;
  uses interface SplitControl as SerialControl;
  uses interface SplitControl as SplitControlFlood;
  uses interface StdControl as RoutingControl;
  uses interface StdControl as DisseminationControl;
  uses interface DisseminationValue<uint32_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Read<uint16_t> as ReadSensor;
  uses interface Timer<TMilli>;
  uses interface Timer<TMilli> as MilliTimer;
  uses interface RootControl;
  uses interface AMSend as AMAODVSend;
  uses interface AMSend as AMFloodSend;
  uses interface AMSend as UARTSend;
  uses interface AMSend as PingReqSend;
  uses interface AMSend as PingRepSend;
  uses interface AMSend as UniversalSend;
  uses interface CollectionPacket;
  uses interface CtpInfo;
  uses interface CtpCongestion;
  uses interface Random;
  uses interface Queue<message_t*>;
  uses interface Pool<message_t>;
  uses interface CollectionDebug;
  uses interface AMPacket;
  uses interface Packet;
  uses interface Packet as RadioPacket;
  uses interface Packet as PingReqPacket;
  uses interface Packet as PingRepPacket;
  uses interface Packet as UniversalPacket;
}


implementation {

  /*
    global variables that determines whether to use CTP (if 1)
    or AODV (if 2) or simple flooding (if 3), as well as overlap
  */
  nx_int32_t prot; //protocol not initially specified
  nx_int16_t overlap; //tells whether the node is in overlapping position or not
  nx_int16_t numNodes; //global variable that will also be injected by TOSSIM

  //CTP variables
  task void uartEchoTask();
  message_t packet;
  message_t uartpacket;
  message_t* recvPtr = &uartpacket;
  uint8_t msglen;
  bool sendBusy = FALSE;
  bool uartbusy = FALSE;
  bool initialBoot = TRUE;
  bool firstTimer = TRUE;
  uint16_t seqno;
  float temp;
  float wind;
  float hum;
  float num = 0;
  enum {
    SEND_INTERVAL = 8192
  };


  //AODV variables
  message_t pkt;
  message_t* p_pkt;
  message_t* aodv_msg;
  aodv_msg_hdr* mReceived;
  nx_uint8_t tempPackaged;
  nx_uint8_t humPackaged;
  nx_uint8_t windPackaged;

  uint16_t src = 10; //source node of AODV send
  uint16_t dest = 19; //destination node of AODV send

  uint8_t prevSeq = 0;
  uint8_t firstMsg = 0;

  rout_msg_t* r;

  //Simple flooding variables
  uint16_t sfSink = 20;
  float temp_f = 0;
  float wind_f = 0;
  float hum_f =0;
  float num_f = 0;
  int16_t tmpSources[10]; //10 must be changed if numFloodNodes is changed
  int16_t msgSources[10];
  message_t floodPkt;
  message_t fPkt;
  bool match;
  uint16_t i;
  uint16_t j;
  uint16_t numFloodNodes = 10; //must be changed according to topo

  //Overlap protocol variables
  message_t ping_req_pkt;
  message_t ping_rep_pkt;
  int16_t overlappingNodes[30]; //30 must be changed if topo size is changed

  //Universal protocol variables
  message_t uPkt;
  nx_uint16_t tempNew;
  nx_uint16_t humNew;
  nx_uint16_t windNew;
  uint16_t tempReceived;
  uint16_t humReceived;
  uint16_t windReceived;

  event void ReadSensor.readDone(error_t err, uint16_t val) { }

  event void Boot.booted() {
    call SplitControlAODV.start();
    call SplitControlFlood.start();
    call SerialControl.start();
  }

  event void SerialControl.startDone(error_t err) {
    call RadioControl.start();
  }
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      initialBoot = TRUE;
    }
  }

  event void SplitControlAODV.startDone(error_t err) {
    if (err == SUCCESS) {
    } else {
      call SplitControlAODV.start();
      }
  }

  event void SplitControlFlood.startDone(error_t err) {
    if (err == SUCCESS) {
    } else {
      call SplitControlFlood.start();
      }
  }
  event void SplitControlAODV.stopDone(error_t err) {}
  event void SplitControlFlood.stopDone(error_t err) {}
  event void RadioControl.stopDone(error_t err) {}
  event void SerialControl.stopDone(error_t err) {}

  void failedSend() {
    dbg("App", "%s: Send failed.\n", __FUNCTION__);
    call CollectionDebug.logEvent(NET_C_DBG_1);
  }

  void sendMessage() {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet, sizeof(TestNetworkMsg));
    uint16_t metric;
    am_addr_t parent = 0;
    
    universal_msg_t* u;
    int16_t universalDest;
    float temp_temp = rand() % 40 + 40;
    float temp_hum = rand() % 20 + 70;
    float temp_wind = rand() % 20;

    
    if(!(overlap == 0)) { //overlaps with something
      u = (universal_msg_t*)call UniversalPacket.getPayload(&uPkt, sizeof(universal_msg_t));
      tempNew = temp_temp;
      humNew = temp_hum;
      windNew = temp_wind;
      u -> temp = tempNew;
      u -> hum = humNew;
      u -> wind = windNew;
      dbg("Universal", "Universal: Universal message packaged with temp %d, hum %d, and wind %d\n", tempNew, humNew, windNew);
  
      //send to connected nodes 
      i = 0;
      while(i < numNodes && overlappingNodes[i] != -1) {
        universalDest = (uint16_t)overlappingNodes[i];
        dbg("CTP", "CTP: Sending universal packet to %d\n", universalDest);
        call UniversalSend.send(universalDest, &uPkt, sizeof(universal_msg_t));
        i++;
      }
    }
    

    

    call CtpInfo.getParent(&parent);
    call CtpInfo.getEtx(&metric);

      msg->source = TOS_NODE_ID;
      msg->seqno = seqno;
      msg->temp = temp_temp;
      msg->hum = temp_hum;
      msg->wind = temp_wind;
      msg->parent = parent;
      msg->hopcount = 0;
      msg->metric = metric;

    if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      failedSend();
      call Leds.led0On();
      dbg("OverlayNetworkC", "%s: Transmission failed.\n", __FUNCTION__);
    }
    else {
      sendBusy = TRUE;
      seqno++;
      dbg("OverlayNetworkC", "%s: Transmission succeeded.\n", __FUNCTION__);
    }
  }

  //This timer used exclusively for CTP nodes
  event void Timer.fired() {
    if(prot == 1) {
      uint32_t nextInt;

      nextInt = call Random.rand32() % SEND_INTERVAL;
      nextInt += SEND_INTERVAL >> 1;
      call Timer.startOneShot(nextInt);
      if (!sendBusy) {
        if(prot == 1) {
          sendMessage();
        }
      }
    }
  }

  //This timer used for AODV and simple flooding nodes
  event void MilliTimer.fired() {

    //needed for AODV millitimer
    universal_msg_t* u;
    int16_t universalDest;

    if(prot == 2) { //if protocol is AODV
      dbg("APPS", "%s\t APPS: MilliTimer.fired()\n", sim_time_string());
      tempPackaged = 40;
      humPackaged = 50;
      windPackaged = 60;
      p_pkt -> data[5] = tempPackaged;
      p_pkt -> data[6] = humPackaged;
      p_pkt -> data[7] = windPackaged;
      call Leds.led0Toggle();
      call AMAODVSend.send(dest, &pkt, sizeof(p_pkt));

      if(!(overlap == 0)) { //if node overlaps with something
        u = (universal_msg_t*)call UniversalPacket.getPayload(&uPkt, sizeof(universal_msg_t));

        u -> temp = tempPackaged;
        u -> hum = humPackaged;
        u -> wind = windPackaged;

        i = 0;
        while(i < numNodes && overlappingNodes[i] != -1) {
          universalDest = (uint16_t)overlappingNodes[i];
          dbg("Flooding", "Flooding: Sending universal packet to %d\n", universalDest);
          call UniversalSend.send(universalDest, &uPkt, sizeof(universal_msg_t));
          i++;
        }
      }

    }
    else if(prot == 3) { //if protocol is Simple flooding
      flood_msg_t* floodMsg = (flood_msg_t*)call Packet.getPayload(&floodPkt, sizeof(flood_msg_t));
      floodMsg -> temp = rand() % 40 + 40;
      floodMsg -> hum = rand() % 20 + 70;
      floodMsg -> wind = rand() % 20;
      i = 0;
      while(i < numFloodNodes) {
        floodMsg -> sources[i] = -1;
        i++;
      }
      call AMFloodSend.send(AM_BROADCAST_ADDR, &floodPkt, sizeof(flood_msg_t));
    }
  }


  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
      call Leds.led0On();
    }
    sendBusy = FALSE;
    dbg("CTP", "CTP Send completed.\n");
  }

  event void AMAODVSend.sendDone(message_t* bufPtr, error_t error) {
    if(prot == 2) {
      dbg("AODV", "AODV: sendDone!!\n");
    }
  }

  event void AMFloodSend.sendDone(message_t* bufPtr, error_t error) {
    if(prot == 3) {
      dbg("Flooding", "\t Flooding: send done\n");
    }
  }

  event void PingReqSend.sendDone(message_t* bufPtr, error_t error) {
    dbg("OverlayNetworkC", "Overlap: Send of overlap ping request done\n");
  }

  event void PingRepSend.sendDone(message_t* bufPtr, error_t error) {
    dbg("OverlayNetworkC", "Overlap: Send of overlap ping reply done\n");
  }

  event void UniversalSend.sendDone(message_t* bufPtr, error_t error) {
    if(error != SUCCESS) {
       dbg("Universal", "Universal: send failed\n");
    } else {
      dbg("Universal", "Universal: send done\n");
    }
 }

  event void DisseminationPeriod.changed() {
    const uint32_t* newVal = call DisseminationPeriod.get();
    call Timer.stop();
    call Timer.startPeriodic(*newVal);
  }

  //This event receives routing protocol specification (CTP = 1, AODV = 2, Simple flooding = 3)
  event message_t* ReceiveRout.receive(message_t* msg, void* payload, uint8_t len) {
    overlap_ping_req_t* pingReq;
    r = (rout_msg_t*)payload;
    prot = r -> routing;
    overlap = r -> overlap;
    numNodes = r -> numNodes;
    dbg("OverlayNetworkC", "Routing protocol for this node (%d) is %d\n", TOS_NODE_ID, prot);
    dbg("OverlayNetworkC", "Overlap status for this node (%d) is %d\n", TOS_NODE_ID, overlap);

    //Set up CTP routing stuff
    if(prot == 1 && initialBoot == TRUE) {
      call DisseminationControl.start();
      call RoutingControl.start();
      if (TOS_NODE_ID % 500 == 0) {
       call RootControl.setRoot();
      }
      seqno = 0;
        call Timer.startOneShot(call Random.rand16() & 0x1ff);
    }

    //Set up AODV routing stuff
    if(prot == 2 && initialBoot == TRUE) {
      dbg("APPS", "%s\t APPS: startDone\n", sim_time_string());
      p_pkt = &pkt;
      if( TOS_NODE_ID == src ) {
        dbg("AODV", "Millitimer started on node %d because src is %d\n", TOS_NODE_ID, src);
        call MilliTimer.startPeriodic(1024);
        }
    }

    if(prot == 3 && initialBoot == TRUE) {
      dbg("APPS", "%s\t Flooding: startDone\n", sim_time_string());
      if( TOS_NODE_ID == sfSink) {
        call MilliTimer.startPeriodic(1000);
      }
    }

    if(overlap != 0) {
      i = 0;
      while(i < numNodes) { 
        overlappingNodes[i] = -1; //initialize all at -1 (no nodes)
        i++;
      }
      pingReq = (overlap_ping_req_t*)call PingReqPacket.getPayload(&ping_req_pkt, sizeof(overlap_ping_req_t));

      pingReq -> prot = prot;
      pingReq -> source = TOS_NODE_ID;

      call PingReqSend.send(AM_BROADCAST_ADDR, &ping_req_pkt, sizeof(overlap_ping_req_t));
    }
    return msg;
  }

  //Universal message receive event (tunneling strategy)
  event message_t* ReceiveUniversal.receive(message_t* msg, void* payload, uint8_t len) {
    //variables needed for CTP nodes
    TestNetworkMsg* networkMsg;
    uint16_t metric;
    am_addr_t parent = 0;

    //variables needed for flood nodes
    flood_msg_t* f;

    //variables needed for AODV nodes
    message_t aodv_pkt;
    message_t* aodv_pkt_p;

    //different responses according to what protocol the node follows
    if(prot == 1) { //if node follows CTP
      universal_msg_t* u;
      u = (universal_msg_t*)payload;
      
      //extract existing fields
      tempReceived = u -> temp;
      humReceived = u -> hum;
      windReceived = u -> wind;
      dbg("CTP", "CTP: universal packet received\n");
      dbg("CTP", "CTP: universal packet says temp is %d\n", tempReceived);
      dbg("CTP", "CTP: universal packet says hum is %d\n", humReceived);
      dbg("CTP", "CTP: universal packet says wind is %d\n", windReceived);

      networkMsg = (TestNetworkMsg*)call Send.getPayload(&packet, sizeof(TestNetworkMsg));
      networkMsg -> temp = tempReceived;
      networkMsg -> hum = humReceived;
      networkMsg -> wind = windReceived;

      //add in remaining fields
      call CtpInfo.getParent(&parent);
      call CtpInfo.getEtx(&metric);

      networkMsg->source = TOS_NODE_ID;
      networkMsg->seqno = seqno;
      networkMsg->parent = parent;
      networkMsg->hopcount = 0;
      networkMsg->metric = metric;

      //send to remaining nodes
      if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      failedSend();
      call Leds.led0On();
      dbg("OverlayNetworkC", "%s: Transmission failed.\n", __FUNCTION__);
      }
      else {
       sendBusy = TRUE;
       seqno++;
       dbg("OverlayNetworkC", "%s: Transmission succeeded.\n", __FUNCTION__);
      }

    } else if(prot == 2) { //if node follows AODV
      universal_msg_t* u;
      u = (universal_msg_t*)payload;
      
      //extract existing fields
      tempReceived = u -> temp;
      humReceived = u -> hum;
      windReceived = u -> wind;
      dbg("AODV", "AODV: universal packet received\n");

      aodv_pkt_p = &aodv_pkt;
      aodv_pkt_p -> data[5] = tempReceived;
      aodv_pkt_p -> data[6] = humReceived;
      aodv_pkt_p -> data[7] = windReceived; //MIGHT HAVE TO CHANGE THIS TO 8 bit

      //send to designated destination
      call AMAODVSend.send(dest, &aodv_pkt, sizeof(aodv_pkt_p));
      

    } else if(prot == 3) {
      universal_msg_t* u;
      u = (universal_msg_t*)payload;
      
      //extract existing fields
      tempReceived = u -> temp;
      humReceived = u -> hum;
      windReceived = u -> wind;
      
      dbg("Flooding", "Flooding: universal packet received\n");
      /*
      dbg("Flooding", "Flooding: universal packet says temp is %d\n", tempReceived);
      dbg("Flooding", "Flooding: universal packet says hum is %d\n", humReceived);
      dbg("Flooding", "Flooding: universal packet says wind is %d\n", windReceived);
      */

      f = (flood_msg_t*)call Packet.getPayload(&fPkt, sizeof(flood_msg_t));
      f -> temp = tempReceived;
      f -> hum = humReceived;
      f -> wind = windReceived;
      //add remaining fields
      
      i = 0;
      while(i < 10) {
        if(i == 0) {
          f -> sources[i] = TOS_NODE_ID;
        }
        else {
          f -> sources[i] = -1;
        }
        i++;
      }

      //send out to rest of simple flooding nodes
      call AMFloodSend.send(AM_BROADCAST_ADDR, &fPkt, sizeof(flood_msg_t));
    }

    return msg;
  }

  //Overlap ping receive events
  event message_t* ReceivePingReq.receive(message_t* msg, void* payload, uint8_t len) {
    overlap_ping_req_t* oReq;
    overlap_ping_rep_t* pingRep;
    uint16_t incomingProt;
    uint16_t replyToNode;

    if(!(overlap==0)) { //if the node overlaps at all
      oReq = (overlap_ping_req_t*)payload;
      incomingProt = oReq -> prot;
      if(incomingProt != prot) { //if not dealing with same protocol as current node
        replyToNode = oReq -> source;

        //send a ping reply to original node to give OK for communication
        pingRep = (overlap_ping_rep_t*)call PingRepPacket.getPayload(&ping_rep_pkt, sizeof(overlap_ping_rep_t));
        pingRep -> dest = TOS_NODE_ID;

        call PingRepSend.send(replyToNode, &ping_rep_pkt, sizeof(overlap_ping_rep_t));
      }
    }

    return msg;
  }

  event message_t* ReceivePingRep.receive(message_t* msg, void* payload, uint8_t len) {
    overlap_ping_rep_t* oRep;
    uint16_t desiredNode;

    oRep = (overlap_ping_rep_t*)payload;
    desiredNode = oRep -> dest;

    //add desiredNode to array of overlappingNodes
    i = 0;
    while(TRUE && i < numNodes) {
      if(overlappingNodes[i] == -1) {
        overlappingNodes[i] = desiredNode;
        break;
      }
      i++;
    }
    dbg("OverlayNetworkC", "\tPingRep received from node %d, added to overlapping array\n", desiredNode);

    return msg;
  }

  //Protocol receive events (different depending upon which protocol node is following)

  event message_t* ReceiveFlood.receive(message_t* msg, void* payload, uint8_t len) {
    flood_msg_t* f;
    flood_msg_t* floodMsgNew;

    //variables needed for universal message send
    universal_msg_t* u;
    int16_t universalDest;

    if(prot == 3) { //if protocol is Flooding
      f = (flood_msg_t*)payload;
      i = 0;
      while(i < numFloodNodes) {
        msgSources[i] = f -> sources[i];
        i++;
      }

      //see if node should ignore this message (if already broadcast)
      i = 0;
      match = FALSE;
      while (i < numFloodNodes) {
        if(msgSources[i] == TOS_NODE_ID) {
          match = TRUE;
          break;
        }
        i++;
      }

      //add ID to source array, send to next nodes if not already received
      if(match == FALSE) {
        dbg("Flooding", "\t Flooding: message received, \n");

        temp_f += f -> temp;
        hum_f += f -> hum;
        wind_f += f -> wind;
        num_f++;
        dbg("Flooding", "\t Flooding: message received, temp is %.3f\n", temp_f/num_f);
        dbg("Flooding", "\t Flooding: message received, hum is %.3f\n", hum_f/num_f);
        dbg("Flooding", "\t Flooding: message received, wind is %.3f\n", wind_f/num_f);

        j = 0;
        while(TRUE && j < numFloodNodes) {
          if(msgSources[j] == -1) {
            msgSources[j] = TOS_NODE_ID;
            break;
          }
          j++;
        }

        //send new message
        floodMsgNew = (flood_msg_t*)call Packet.getPayload(&floodPkt, sizeof(flood_msg_t));
        floodMsgNew -> temp = f -> temp;
        floodMsgNew -> hum = f -> hum;
        floodMsgNew -> wind = f -> wind;
        i = 0;
        while(i < numFloodNodes) {
          floodMsgNew -> sources[i] = msgSources[i];
          i++;
        }
        call AMFloodSend.send(AM_BROADCAST_ADDR, &floodPkt, sizeof(flood_msg_t));

        //send universal message
        tempNew = f->temp;
        humNew = f->hum;
        windNew = f->wind;

        
        if(!(overlap == 0)) { //overlaps with something
          u = (universal_msg_t*)call UniversalPacket.getPayload(&uPkt, sizeof(universal_msg_t));
          u -> temp = tempNew;
          u -> hum = humNew;
          u -> wind = windNew;
          dbg("Universal", "Universal: Universal message packaged with temp %d, hum %d, and wind %d\n", tempNew, humNew, windNew);
      
          //send to connected nodes 
          i = 0;
          while(i < numNodes && overlappingNodes[i] != -1) {
            universalDest = (uint16_t)overlappingNodes[i];
            dbg("Flooding", "Flooding: Sending universal packet to %d\n", universalDest);
            call UniversalSend.send(universalDest, &uPkt, sizeof(universal_msg_t));
            i++;
          }

        }
      } else {
        //dbg("Flooding", "\t Flooding: message IGNORED\n");
      }
    }
    return msg;
  }


  event message_t* ReceiveAODV.receive(message_t* msg, void* payload, uint8_t len) {
    //uint16_t aodv_temp;
    //uint16_t aodv_hum;
    //uint16_t aodv_wind;
    //aodv_hdr = payload;
    //message_t* m;
    mReceived = (aodv_msg_hdr*)msg->data;
    if(prot == 2) { //if protocol is aodv_msg
      i = 0;
      for( i=0;i<3;i++ ) {
        dbg("AODV", "\t AODV: data[%d] is %d\n", i, mReceived->data[i]);
      }
      /*
      tempReceived = aodv_msg -> data[0];
      humReceived = aodv_msg -> data[1];
      windReceived = aodv_msg -> data[2];
      dbg("AODV", "%s\t AODV: Received!!!!\n", sim_time_string());
      dbg("AODV", "\t AODV: Temp is %d\n", tempReceived);
      dbg("AODV", "\t AODV: Hum is %d\n", humReceived);
      dbg("AODV", "\t AODV: Wind is %d\n", windReceived);
      */

      /*
      aodv_temp = aodv_msg -> temp;
      aodv_hum = aodv_msg -> hum;
      aodv_wind = aodv_msg -> wind;
      dbg("AODV", "AODV temp value is %d\n", aodv_temp);
      dbg("AODV", "AODV hum value is %d\n", aodv_hum);
      dbg("AODV", "AODV wind value is %d\n", aodv_wind;
      */
    }
    return msg;
  }

  event message_t* ReceiveCTP.receive(message_t* msg, void* payload, uint8_t len) {
    //variables needed for universal message sends

    if(prot == 1) { //if protocol is CTP
      TestNetworkMsg* rcm = (TestNetworkMsg*) payload;
      tempReceived = rcm -> temp;
      humReceived = rcm -> hum;
      windReceived = rcm -> wind;
      temp += tempReceived;
      hum  += humReceived;
      wind += windReceived;
      num++;
      /*
      dbg("CTP", "CTP: Received temp value is %d\n", tempReceived);
      dbg("CTP", "CTP: Received temp value is %d\n", humReceived);
      dbg("CTP", "CTP: Received temp value is %d\n", windReceived);
      */
      dbg("CTP", "CTP: Temp value is %.3f.\n", temp/num);
      dbg("CTP", "CTP: Wind value is %.3f.\n", wind/num);
      dbg("CTP", "CTP: Humidity value is %.3f.\n", hum/num);
      dbg("OverlayNetworkC", "CTP Node received packet at %s from node %hhu.\n", sim_time_string(), call CollectionPacket.getOrigin(msg));
      dbg("OverlayNetworkC", "Current overlap status is %d\n", overlap);
      call Leds.led1Toggle();
      

      if (call CollectionPacket.getOrigin(msg) == 1) {
        if (firstMsg == 1) {
        if (call CollectionPacket.getSequenceNumber(msg) - prevSeq > 1) {
          call Leds.led2On();
        }
          } else {
            firstMsg = 1;
          }
          prevSeq = call CollectionPacket.getSequenceNumber(msg);
      }
     

      if (!call Pool.empty() && call Queue.size() < call Queue.maxSize()) {
        message_t* tmp = call Pool.get();
        call Queue.enqueue(msg);
        if (!uartbusy) {
          post uartEchoTask();
        }
        return tmp;
      }     
    }
    return msg;
 }

 task void uartEchoTask() {
    dbg("Traffic", "CTP node sending packet to UART.\n");
   if (call Queue.empty()) {
     return;
   }
   else if (!uartbusy) {
     message_t* msg = call Queue.dequeue();
     dbg("Traffic", "Sending packet to UART.\n");
     if (call UARTSend.send(0xffff, msg, call RadioPacket.payloadLength(msg)) == SUCCESS) {
       uartbusy = TRUE;
     }
     else {
      call CollectionDebug.logEventMsg(NET_C_DBG_2,
				       call CollectionPacket.getSequenceNumber(msg),
				       call CollectionPacket.getOrigin(msg),
				       call AMPacket.destination(msg));
     }
   }
 }

  event void UARTSend.sendDone(message_t *msg, error_t error) {
    dbg("Traffic", "UART send done.\n");
    uartbusy = FALSE;
    call Pool.put(msg);
    if (!call Queue.empty()) {
      post uartEchoTask();
    }
    else {
      //        call CtpCongestion.setClientCongested(FALSE);
    }
  }

  command nx_int32_t GetProt.get() {
    return prot;
  }

  /* Default implementations for CollectionDebug calls.
   * These allow CollectionDebug not to be wired to anything if debugging
   * is not desired. */


    default command error_t CollectionDebug.logEvent(uint8_t type) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    default command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }

}
