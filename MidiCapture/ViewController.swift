//
//  ViewController.swift
//  MidiCapture
//
//  Created by Stephen Rowe on 1/11/17.
//  Copyright © 2017 Stephen Rowe. All rights reserved.
//

import Cocoa
import CoreMIDI


var gtextField:NSTextField!
var arrayMidiIn = Array<String>()
var midiClient: MIDIClientRef = 0;
var outPort:MIDIPortRef = 0;
var inPort:MIDIPortRef = 0
var dest:MIDIEndpointRef = 0
var chanNum:UInt8 = 0
var packet1:MIDIPacket = MIDIPacket()

class ViewController: NSViewController {
    
    
    @IBOutlet var text: NSScrollView!
    
    @IBOutlet var channel: NSComboBox!
    //@IBAction func chanChanged(_ sender: Any) {
    //    chanNum = UInt8(channel.indexOfSelectedItem)
    //}
    @IBAction func chanChanged(_ sender: Any) {
        chanNum = UInt8(channel.indexOfSelectedItem)
    }
    
    func runTimeCode(){
        if arrayMidiIn.count > 0{
            for str in arrayMidiIn{
                //text.insertText(str)
                text.documentView?.insertText(arrayMidiIn.popLast())
                text.documentView?.insertNewline(text)
            }
        }
        else{
                   }
        //text.displayIfNeeded()
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        channel.removeAllItems()
        channel.addItem(withObjectValue: "Chan 1")
        channel.addItem(withObjectValue: "Chan 2")
        channel.addItem(withObjectValue: "Chan 3")
        channel.addItem(withObjectValue: "Chan 4")
        channel.addItem(withObjectValue: "Chan 5")
        channel.addItem(withObjectValue: "Chan 6")
        channel.addItem(withObjectValue: "Chan 7")
        channel.addItem(withObjectValue: "Chan 8")
        
        channel.addItem(withObjectValue: "Chan 9")
        channel.addItem(withObjectValue: "Chan 10")
        channel.addItem(withObjectValue: "Chan 11")
        channel.addItem(withObjectValue: "Chan 12")
        channel.addItem(withObjectValue: "Chan 13")
        channel.addItem(withObjectValue: "Chan 14")
        channel.addItem(withObjectValue: "Chan 15")
        channel.addItem(withObjectValue: "Chan 16")
        //gtextField.self = text.self
        
        MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient);
        MIDIOutputPortCreate(midiClient, "MidiTest_OutPort" as CFString, &outPort);
        
        
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(runTimeCode), userInfo: nil, repeats: true)
        
        text.insertText("Begin")
        text.displayIfNeeded()
        let destNames = getDestinationNames();
        
        print("Number of MIDI Destinations: \(destNames.count)");
        for destName in destNames
        {
            print("  Destination: \(destName)");
        }
        
        let sourceNames = getSourceNames();
        
        print("\nNumber of MIDI Sources: \(sourceNames.count)");
        for sourceName in sourceNames
        {
            print("  Source: \(sourceName)");
        }
        
        
        
        
        packet1 = MIDIPacket();
        packet1.timeStamp = 0;
        packet1.length = 3;
        packet1.data.0 = 0x90 + 1; // Note On event channel 1
        packet1.data.1 = 0x3C; // Note C3
        packet1.data.2 = 100; // Velocity
        
        var packetList:MIDIPacketList = MIDIPacketList(numPackets: 1, packet: packet1);
        
        let destinationNames = getDestinationNames()
        for (index,destName) in destinationNames.enumerated()
        {
            print("Destination #\(index): \(destName)")
        }
        
        let destNum = 2
        print("Using destination #\(destNum)")
        
        dest = MIDIGetDestination(destNum);
        print("Playing note for 1 second on channel 1")
        MIDISend(outPort, dest, &packetList);
        packet1.data.0 = 0x80 + 1; // Note Off event channel 1
        packet1.data.2 = 0; // Velocity
        sleep(1);
        packetList = MIDIPacketList(numPackets: 1, packet: packet1);
        MIDISend(outPort, dest, &packetList);
        print("Note off sent")
        
        
        var src:MIDIEndpointRef = MIDIGetSource(2)
        
        MIDIClientCreate("MidiTestClient" as CFString, nil, nil, &midiClient)
        MIDIInputPortCreate(midiClient, "MidiTest_InPort" as CFString, MyMIDIReadProc, nil, &inPort)
        
        MIDIPortConnectSource(inPort, src, &src)
        
        //channel.se

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    




}
var cnt = 0
func MyMIDIReadProc(pktList: UnsafePointer<MIDIPacketList>,
                    readProcRefCon: UnsafeMutableRawPointer?, srcConnRefCon: UnsafeMutableRawPointer?) -> Void
{
    var packetList:MIDIPacketList = pktList.pointee
    let srcRef:MIDIEndpointRef = srcConnRefCon!.load(as: MIDIEndpointRef.self)
    
    //print("MIDI Received From Source: \(getDisplayName(srcRef))")
    
    var packet:MIDIPacket = packetList.packet
    for _ in 1...packetList.numPackets
    {
        let bytes = Mirror(reflecting: packet.data).children
        var dumpStr = ""
        
        // bytes mirror contains all the zero values in the ridiulous packet data tuple
        // so use the packet length to iterate.
        var i = packet.length
        for (_, attr) in bytes.enumerated()
        {
            dumpStr += String(format:"%02X ", attr.value as! UInt8)
            i -= 1
            if (i <= 0)
            {
                break
            }
        }
        
        
        if packet.data.0 != 0xfe {
          
            arrayMidiIn.append(dumpStr)
        }
       
        
        
       
       
        
        if (packet.data.0 & 0xf0) == 0x90 || (packet.data.0 & 0xf0) == 0x80{
            dest = MIDIGetDestination(2);
            packet1 = MIDIPacket();
            packet1.timeStamp = 0;
            packet1.length = 3;
            packet1.data.0 = packet.data.0 | chanNum; // Note On event channel 1
            packet1.data.1 = packet.data.1; // Note C3
            packet1.data.2 = packet.data.2; // Velocity
            packetList = MIDIPacketList(numPackets: 1, packet: packet1);
            
           
            MIDISend(outPort, dest, &packetList);
            
            print(dumpStr)
        }
        packet = MIDIPacketNext(&packet).pointee
    }
}


func getDisplayName(_ obj: MIDIObjectRef) -> String
{
    var param: Unmanaged<CFString>?
    var name: String = "Error"
    
    let err: OSStatus = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
    if err == OSStatus(noErr)
    {
        name =  param!.takeRetainedValue() as String
    }
    
    return name
}

func getDestinationNames() -> [String]
{
    var names:[String] = [];
    
    let count: Int = MIDIGetNumberOfDestinations();
    for i in 0..<count {
        let endpoint:MIDIEndpointRef = MIDIGetDestination(i);
        
        if (endpoint != 0)
        {
            names.append(getDisplayName(endpoint));
        }
    }
    return names;
}

func getSourceNames() -> [String]
{
    var names:[String] = [];
    
    let count: Int = MIDIGetNumberOfSources();
    for i in 0..<count {
        let endpoint:MIDIEndpointRef = MIDIGetSource(i);
        if (endpoint != 0)
        {
            names.append(getDisplayName(endpoint));
        }
    }
    return names;
}





//var midiClient: MIDIClientRef = 0


