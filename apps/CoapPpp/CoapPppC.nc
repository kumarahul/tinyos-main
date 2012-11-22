/*
 * Copyright (c) 2011 University of Bremen, TZI
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef COAP_RESOURCE_KEY
#include "StorageVolumes.h"
#endif

#include <iprouting.h>

#include "ppp.h"
#include "tinyos_coap_resources.h"

configuration CoapPppC {

} implementation {
  components MainC;
  components LedsC;
  components CoapPppP;

  CoapPppP.Boot -> MainC;
  CoapPppP.Leds -> LedsC;

  components PppDaemonC;
  CoapPppP.PppControl -> PppDaemonC;

  components PppIpv6C;
  PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
  PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
  PppIpv6C.Ppp -> PppDaemonC;
  PppIpv6C.LowerLcpAutomaton -> PppDaemonC;

  CoapPppP.Ipv6LcpAutomaton -> PppIpv6C;
  CoapPppP.PppIpv6 -> PppIpv6C;
  CoapPppP.Ppp -> PppDaemonC;

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
  components PlatformHdlcUartC as HdlcUartC;
#else
  components DefaultHdlcUartC as HdlcUartC;
#endif
  PppDaemonC.HdlcUart -> HdlcUartC;
  PppDaemonC.UartControl -> HdlcUartC;

  // SDH : don't bother including the PppPrintfC by default
  /*  components PppPrintfC, PppC;
  PppPrintfC.Ppp -> PppDaemonC;
  PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
  PppPrintfC.Ppp -> PppC;*/

  components IPStackC, IPForwardingEngineP, IPPacketC;
  IPForwardingEngineP.IPForward[ROUTE_IFACE_PPP] -> CoapPppP.IPForward;
  CoapPppP.IPControl -> IPStackC;
  CoapPppP.ForwardingTable -> IPStackC;
  CoapPppP.IPPacket -> IPPacketC;

  // UDP shell on port 2000
  //components UDPShellC;

  // prints the routing table
  //components RouteCmdC;

  /*
#ifndef IN6_PREFIX
  components Dhcp6ClientC;
  CoapPppP.Dhcp6Info -> Dhcp6ClientC;
#endif
  */

  components LibCoapAdapterC;
#ifdef COAP_SERVER_ENABLED
  components CoapUdpServerC;
  components new UdpSocketC() as UdpServerSocket;
  CoapPppP.CoAPServer -> CoapUdpServerC;
  CoapUdpServerC.LibCoapServer -> LibCoapAdapterC.LibCoapServer;
  LibCoapAdapterC.UDPServer -> UdpServerSocket;

#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  components LocalIeeeEui64C;
#endif

#ifdef COAP_RESOURCE_DEFAULT
  components new CoapDefaultResourceC(INDEX_DEFAULT);
  CoapUdpServerC.CoapResource[INDEX_DEFAULT] -> CoapDefaultResourceC.CoapResource;
  CoapDefaultResourceC.Leds -> LedsC;
  CoapDefaultResourceC.CoAPServer ->  CoapUdpServerC;//for POST/DELETE
#endif

#if defined (COAP_RESOURCE_TEMP)  || defined (COAP_RESOURCE_HUM) || defined (COAP_RESOURCE_ALL)
  components new SensirionSht11C() as HumTempSensor;
#endif

#ifdef COAP_RESOURCE_TEMP
  components new CoapReadResourceC(uint16_t, INDEX_TEMP) as CoapReadTempResource;
  components new CoapBufferTempTranslateC() as CoapBufferTempTranslate;
  CoapReadTempResource.Read -> CoapBufferTempTranslate.ReadTemp;
  CoapBufferTempTranslate.Read -> HumTempSensor.Temperature;
  CoapUdpServerC.CoapResource[INDEX_TEMP] -> CoapReadTempResource.CoapResource;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  CoapReadTempResource.LocalIeeeEui64 -> LocalIeeeEui64C;
#endif
#endif

#ifdef COAP_RESOURCE_HUM
  components new CoapReadResourceC(uint16_t, INDEX_HUM) as CoapReadHumResource;
  components new CoapBufferHumTranslateC() as CoapBufferHumTranslate;
  CoapReadHumResource.Read -> CoapBufferHumTranslate.ReadHum;
  CoapBufferHumTranslate.Read -> HumTempSensor.Humidity;
  CoapUdpServerC.CoapResource[INDEX_HUM] -> CoapReadHumResource.CoapResource;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  CoapReadHumResource.LocalIeeeEui64 -> LocalIeeeEui64C;
#endif
#endif

#if defined (COAP_RESOURCE_VOLT)  || defined (COAP_RESOURCE_ALL)
  components new VoltageC() as VoltSensor;
#endif

#ifdef COAP_RESOURCE_VOLT
  components new CoapReadResourceC(uint16_t, INDEX_VOLT) as CoapReadVoltResource;
  components new CoapBufferVoltTranslateC() as CoapBufferVoltTranslate;
  CoapReadVoltResource.Read -> CoapBufferVoltTranslate.ReadVolt;
  CoapBufferVoltTranslate.Read -> VoltSensor.Read;
  CoapUdpServerC.CoapResource[INDEX_VOLT] -> CoapReadVoltResource.CoapResource;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  CoapReadVoltResource.LocalIeeeEui64 -> LocalIeeeEui64C;
#endif
#endif

#ifdef COAP_RESOURCE_ALL
  components new CoapReadResourceC(val_all_t, INDEX_ALL) as CoapReadAllResource;
  components new SensirionSht11C() as HumTempSensorAll;
  components CoapResourceCollectorC;
  CoapReadAllResource.Read -> CoapResourceCollectorC.ReadAll;
  components new CoapBufferTempTranslateC() as CoapBufferTempTranslateAll;
  CoapResourceCollectorC.ReadTemp -> CoapBufferTempTranslateAll.ReadTemp;
  CoapBufferTempTranslateAll.Read -> HumTempSensorAll.Temperature;
  components new CoapBufferHumTranslateC() as CoapBufferHumTranslateAll;
  CoapResourceCollectorC.ReadHum -> CoapBufferHumTranslateAll.ReadHum;
  CoapBufferHumTranslateAll.Read -> HumTempSensorAll.Humidity;
  components new CoapBufferVoltTranslateC() as CoapBufferVoltTranslateAll;
  CoapResourceCollectorC.ReadVolt -> CoapBufferVoltTranslateAll.ReadVolt;
  CoapBufferVoltTranslateAll.Read -> VoltSensor.Read;
  CoapUdpServerC.CoapResource[INDEX_ALL] -> CoapReadAllResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_KEY
  components new CoapFlashResourceC(INDEX_KEY) as CoapFlashResource;
  components new ConfigStorageC(VOLUME_CONFIGKEY);
  CoapFlashResource.ConfigStorage -> ConfigStorageC.ConfigStorage;
  CoapPppP.Mount  -> ConfigStorageC.Mount;
  CoapUdpServerC.CoapResource[INDEX_KEY]  -> CoapFlashResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_LED
  components new CoapLedResourceC(INDEX_LED) as CoapLedResource;
  CoapLedResource.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_LED]  -> CoapLedResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_ROUTE
  components new CoapRouteResourceC(uint16_t, INDEX_ROUTE) as CoapReadRouteResource;
  CoapReadRouteResource.ForwardingTable -> IPStackC;
  CoapUdpServerC.CoapResource[INDEX_ROUTE] -> CoapReadRouteResource.CoapResource;
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_TEST
  components new CoapEtsiTestResourceC(INDEX_ETSI_TEST);
  CoapUdpServerC.CoapResource[INDEX_ETSI_TEST] -> CoapEtsiTestResourceC.CoapResource;
  CoapEtsiTestResourceC.Leds -> LedsC;
  CoapEtsiTestResourceC.CoAPServer ->  CoapUdpServerC;//for POST/DELETE
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_SEPARATE
  components new CoapEtsiSeparateResourceC(INDEX_ETSI_SEPARATE);
  CoapUdpServerC.CoapResource[INDEX_ETSI_SEPARATE] -> CoapEtsiSeparateResourceC.CoapResource;
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_SEGMENT
  components new CoapEtsiSegmentResourceC(INDEX_ETSI_SEGMENT);
  CoapEtsiSegmentResourceC.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_ETSI_SEGMENT] -> CoapEtsiSegmentResourceC.CoapResource;
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_LARGE
  components new CoapEtsiLargeResourceC(INDEX_ETSI_LARGE);
  CoapEtsiLargeResourceC.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LARGE] -> CoapEtsiLargeResourceC.CoapResource;
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_OBSERVE
  components new CoapEtsiObserveResourceC(INDEX_ETSI_OBSERVE);
  CoapEtsiObserveResourceC.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_ETSI_OBSERVE] -> CoapEtsiObserveResourceC.CoapResource;
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_MULTI_FORMAT
  components new CoapEtsiMultiFormatResourceC(INDEX_ETSI_MULTI_FORMAT);
  CoapEtsiMultiFormatResourceC.Leds -> LedsC;
  CoapUdpServerC.CoapResource[INDEX_ETSI_MULTI_FORMAT] -> CoapEtsiMultiFormatResourceC.CoapResource;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
  CoapEtsiMultiFormatResourceC.LocalIeeeEui64 -> LocalIeeeEui64C;
#endif
#endif

#ifdef COAP_RESOURCE_ETSI_IOT_LINK
  components new CoapEtsiLinkResourceC(INDEX_ETSI_LINK1) as Link1Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LINK1] -> Link1Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_LINK2) as Link2Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LINK2] -> Link2Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_LINK3) as Link3Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LINK3] -> Link3Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_LINK4) as Link4Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LINK4] -> Link4Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_LINK5) as Link5Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_LINK5] -> Link5Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_PATH) as PathResource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_PATH] -> PathResource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_PATH1) as Path1Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_PATH1] -> Path1Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_PATH2) as Path2Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_PATH2] -> Path2Resource.CoapResource;
  components new CoapEtsiLinkResourceC(INDEX_ETSI_PATH3) as Path3Resource;
  CoapUdpServerC.CoapResource[INDEX_ETSI_PATH3] -> Path3Resource.CoapResource;
#endif

#endif

#ifdef COAP_CLIENT_ENABLED
  components CoapUdpClientC;
  components new UdpSocketC() as UdpClientSocket;
  CoapPppP.CoAPClient -> CoapUdpClientC;
  CoapUdpClientC.LibCoapClient -> LibCoapAdapterC.LibCoapClient;
  LibCoapAdapterC.UDPClient -> UdpClientSocket;
  CoapPppP.ForwardingTableEvents -> IPStackC.ForwardingTableEvents;
#endif
  }
