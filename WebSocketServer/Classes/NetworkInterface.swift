//
//  NetworkInterface.swift
//  WebSocketServer
//
//  Created by Khazan on 2023/4/6.
//

import Foundation

public class NetworkInterface {
    
    public struct NetworkInterfaceInfo {
        let name: String
        let ip: String
        let netmask: String
    }
    
    public static func enumerate() -> [NetworkInterfaceInfo] {
        var interfaces = [NetworkInterfaceInfo]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while( ptr != nil) {

                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                        var mask = ptr!.pointee.ifa_netmask.pointee

                        // Convert interface address to a human readable string:
                        let zero  = CChar(0)
                        var hostname = [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        var netmask =  [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            let address = String(cString: hostname)
                            let name = ptr!.pointee.ifa_name!
                            let ifname = String(cString: name)


                            if (getnameinfo(&mask, socklen_t(mask.sa_len), &netmask, socklen_t(netmask.count),
                                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                let netmaskIP = String(cString: netmask)

                                let info = NetworkInterfaceInfo(name: ifname,
                                                                ip: address,
                                                                netmask: netmaskIP)
                                interfaces.append(info)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return interfaces
    }
}
