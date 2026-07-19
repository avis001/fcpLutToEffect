import Foundation

/// Generates the .moef (Motion effect template) XML for a single Custom LUT
/// effect. The structure mirrors Final Cut Pro's built-in color-preset
/// templates; the filter is FCP's internal Custom LUT filter (PAELUTEffect).
enum MoefTemplate {
    /// - Parameters:
    ///   - lutBlob: OzBase64-encoded channel value for the LUT reference parameter.
    static func render(lutBlob: String) -> String {
        template.replacingOccurrences(of: "{LUT_BLOB}", with: lutBlob)
    }

    private static let template = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ozxmlscene>
<ozml version="5.13">

<displayversion>5.7</displayversion>

<factory id="1" uuid="46c844a813d311d8a438000a95af9f7e">
\t<description>Channel</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>

<factory id="2" uuid="65cb4dc9d4504fa281921f5f751fba06">
\t<description>Widget</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>

<factory id="3" uuid="66fc0d6af6a911d6a7a7000393670732">
\t<description>Image</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>

<factory id="4" uuid="7d468273c013498e9806a0d7bc32fddf">
\t<description>Project</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>

<factory id="5" uuid="dbca752470fd11d7980100039389b702">
\t<description>Channel</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>

<factory id="6" uuid="deca4859b16011d7a12d0003936f6f92">
\t<description>ProPlugin Filter</description>
\t<manufacturer>Apple</manufacturer>
\t<version>1</version>
</factory>


<template>
\t<flags>1</flags>
</template>

<build></build>

<description></description>

<scene>
\t<sceneSettings>
\t\t<width>1920</width>
\t\t<height>1080</height>
\t\t<duration>300</duration>
\t\t<shouldOverrideFCDuration>0</shouldOverrideFCDuration>
\t\t<frameRate>30</frameRate>
\t\t<NTSC>1</NTSC>
\t\t<pixelAspectRatio>1</pixelAspectRatio>
\t\t<workingGamut>1</workingGamut>
\t\t<viewGamut>-1</viewGamut>
\t\t<optimizeForDisplay>0</optimizeForDisplay>
\t\t<backgroundColor red="0" green="0" blue="0" alpha="1"/>
\t\t<audioChannels>2</audioChannels>
\t\t<audioBitsPerSample>32</audioBitsPerSample>
\t\t<fieldRenderingMode>0</fieldRenderingMode>
\t\t<motionBlurSamples>8</motionBlurSamples>
\t\t<motionBlurDuration>1</motionBlurDuration>
\t\t<sharpScaling>0</sharpScaling>
\t\t<startTimecode>0</startTimecode>
\t\t<backgroundMode>0</backgroundMode>
\t\t<reflectionRecursionLimit>2</reflectionRecursionLimit>
\t\t<glyphOSCMode>0</glyphOSCMode>
\t\t<animateFlag>0</animateFlag>
\t\t<parameterColorSpaceID>3</parameterColorSpaceID>
\t\t<savePreviewMovie>0</savePreviewMovie>
\t\t<Object3DEnvironments>100</Object3DEnvironments>
\t\t<DRTSupport>1</DRTSupport>
\t</sceneSettings>
\t<publishSettings>
\t\t<version>2</version>
\t\t<target object="10293" channel="./3" name="LUT"/>
\t\t<target object="10293" channel="./100" name="Input Color Space"/>
\t\t<target object="10293" channel="./101" name="Output Color Space"/>
\t\t<target object="10293" channel="./10001" name="Mix"/>
\t</publishSettings>
\t<timeRange offset="0 1 1 0" duration="1201200 120000 1 0"/>
\t<playRange offset="0 1 1 0" duration="1201200 120000 1 0"/>
\t<flags>1</flags>
\t<audioTracks>0</audioTracks>
\t<timemarkerset/>
\t<guideset/>
\t<curvesets selected="1"/>
\t<scenenode name="Project" id="10286" factoryID="4" version="5">
\t\t<scenenode name="Widget" id="10287" factoryID="2" version="5">
\t\t\t<flags>0</flags>
\t\t\t<timing in="0 1 1 0" out="-4004 120000 1 0" offset="0 1 1 0"/>
\t\t\t<foldFlags>0</foldFlags>
\t\t\t<baseFlags>16</baseFlags>
\t\t\t<parameter name="Properties" id="1" flags="8589938704"/>
\t\t\t<parameter name="Object" id="2" flags="8589938704">
\t\t\t\t<parameter name="Options" id="103" flags="8589938688"/>
\t\t\t\t<parameter name="Hidden" id="102" flags="8589934608" default="0" value="1"/>
\t\t\t\t<parameter name="Snapshots" id="101" flags="8589938706"/>
\t\t\t\t<parameter name="Widget" id="100" flags="8589934608" default="1.7777777777777777" value="1.7777777777777777"/>
\t\t\t</parameter>
\t\t</scenenode>
\t\t<flags>0</flags>
\t\t<timing in="0 1 1 0" out="-4004 120000 1 0" offset="0 1 1 0"/>
\t\t<foldFlags>0</foldFlags>
\t\t<baseFlags>16</baseFlags>
\t\t<parameter name="Properties" id="1" flags="8589938704">
\t\t\t<parameter name="HDR White Level" id="103" flags="8589967376" default="0.95" value="0.95"/>
\t\t</parameter>
\t\t<parameter name="Object" id="2" flags="8589938704"/>
\t</scenenode>
\t<layer name="Group" id="10288">
\t\t<scenenode name="Effect Source" id="10291" factoryID="3" version="5">
\t\t\t<validTracks>1</validTracks>
\t\t\t<aspectRatio>1</aspectRatio>
\t\t\t<flags>0</flags>
\t\t\t<timing in="0 1 1 0" out="1197196 120000 1 0" offset="0 1 1 0"/>
\t\t\t<foldFlags>24576</foldFlags>
\t\t\t<baseFlags>524304</baseFlags>
\t\t\t<parameter name="Properties" id="1" flags="8589938704">
\t\t\t\t<parameter name="Media" id="324" flags="8589938704">
\t\t\t\t\t<foldFlags>4</foldFlags>
\t\t\t\t\t<parameter name="Source Media" id="300" flags="81621221392" default="3192331631" value="3192331631"/>
\t\t\t\t\t<parameter name="Source Media" id="325" flags="8590000146"/>
\t\t\t\t</parameter>
\t\t\t\t<parameter name="Page Number" id="301" flags="8589934610" default="1" value="1"/>
\t\t\t\t<parameter name="Retime Value" id="304" flags="8590066066" default="1" value="1"/>
\t\t\t\t<parameter name="Retime Value Cache" id="319" flags="8590065810" default="1" value="1"/>
\t\t\t</parameter>
\t\t\t<parameter name="Object" id="2" flags="8589938704">
\t\t\t\t<parameter name="Drop Zone" id="311" flags="8589934738" default="0" value="1"/>
\t\t\t\t<parameter name="Type" id="321" flags="8590000146" default="0" value="3"/>
\t\t\t\t<parameter name="Fill Opaque" id="328" flags="8606711824" default="0" value="0"/>
\t\t\t\t<parameter name="Clear" id="315" flags="8606777360" default="0" value="0"/>
\t\t\t\t<parameter name="Width" id="313" flags="8589934610" default="1" value="1920"/>
\t\t\t\t<parameter name="Height" id="314" flags="8589934610" default="1" value="1080"/>
\t\t\t</parameter>
\t\t\t<filter name="Custom LUT" id="10293" factoryID="6" pluginUUID="14B39AEF-607D-42DF-98DD-DB3DD345E925" pluginVersion="2" pluginName="PAELUTEffect" pluginDynamicParams="0">
\t\t\t\t<timing in="0 1 1 0" out="1197196 120000 1 0" offset="0 1 1 0"/>
\t\t\t\t<baseFlags>8858370065</baseFlags>
\t\t\t\t<parameter name="" id="3" flags="12884901888">
\t\t\t\t\t<numberOfKeypoints>0</numberOfKeypoints>
\t\t\t\t\t<defaultVal>{LUT_BLOB}</defaultVal>
\t\t\t\t\t<dataValue>{LUT_BLOB}</dataValue>
\t\t\t\t</parameter>
\t\t\t\t<parameter name="Mix" id="10001" flags="12901679104" default="1" value="1"/>
\t\t\t</filter>
\t\t</scenenode>
\t\t<aspectRatio>1</aspectRatio>
\t\t<flags>0</flags>
\t\t<timing in="0 1 1 0" out="1197196 120000 1 0" offset="0 1 1 0"/>
\t\t<foldFlags>0</foldFlags>
\t\t<baseFlags>524304</baseFlags>
\t\t<parameter name="Properties" id="1" flags="8589938704"/>
\t\t<parameter name="Object" id="2" flags="8589938704">
\t\t\t<parameter name="Fixed Width" id="302" flags="12884901908" default="1920" value="1920"/>
\t\t\t<parameter name="Fixed Height" id="303" flags="12884901908" default="1080" value="1080"/>
\t\t\t<parameter name="Flatten" id="311" flags="8589934610" default="0" value="0"/>
\t\t\t<parameter name="Layer Order" id="305" flags="8589934610" default="0" value="0"/>
\t\t\t<parameter name="Aperture Width" id="312" flags="12884901906" default="1920" value="1920"/>
\t\t\t<parameter name="Aperture Height" id="313" flags="12884901906" default="1080" value="1080"/>
\t\t</parameter>
\t</layer>

\t<footage name="Media Layer" id="10290">
\t\t<clip name="Drop Zone" id="3192331631">
\t\t\t<pathURL>Drop Zone.tiff</pathURL>
\t\t\t<missingWidth>1200</missingWidth>
\t\t\t<missingHeight>1200</missingHeight>
\t\t\t<missingDuration>0.033333333333333333</missingDuration>
\t\t\t<missingDynamicRangeType>0</missingDynamicRangeType>
\t\t\t<creationDuration>1</creationDuration>
\t\t\t<mediaID></mediaID>
\t\t\t<flags>0</flags>
\t\t\t<timing in="0 1 1 0" out="0 120000 1 0" offset="0 1 1 0"/>
\t\t\t<foldFlags>0</foldFlags>
\t\t\t<baseFlags>524304</baseFlags>
\t\t\t<parameter name="Properties" id="1" flags="8589938704"/>
\t\t\t<parameter name="Object" id="2" flags="8589938704">
\t\t\t\t<parameter name="Pixel Aspect Ratio" id="104" flags="12884901888" default="1" value="1"/>
\t\t\t\t<parameter name="Frame Rate" id="107" flags="8589934592" default="0" value="30"/>
\t\t\t\t<parameter name="Fixed Width" id="114" flags="12884901888" default="1200" value="1200"/>
\t\t\t\t<parameter name="Fixed Height" id="115" flags="12884901888" default="1200" value="1200"/>
\t\t\t\t<parameter name="Use Background Color" id="116" flags="8589934594" default="0" value="0"/>
\t\t\t\t<parameter name="Background Color" id="117" flags="8589971458">
\t\t\t\t\t<foldFlags>15</foldFlags>
\t\t\t\t\t<parameter name="Red" id="1" flags="8589967376" default="1" value="1"/>
\t\t\t\t\t<parameter name="Green" id="2" flags="8589967376" default="1" value="1"/>
\t\t\t\t\t<parameter name="Blue" id="3" flags="8589967376" default="1" value="1"/>
\t\t\t\t</parameter>
\t\t\t\t<parameter name="Missing Is Still" id="128" flags="8589934610" default="0" value="1"/>
\t\t\t</parameter>
\t\t</clip>
\t\t<flags>0</flags>
\t\t<timing in="0 1 1 0" out="-4004 120000 1 0" offset="0 1 1 0"/>
\t\t<foldFlags>0</foldFlags>
\t\t<baseFlags>524304</baseFlags>
\t\t<parameter name="Properties" id="1" flags="8589938704"/>
\t\t<parameter name="Object" id="2" flags="8589938704"/>
\t</footage>
</scene>

</ozml>
"""
}
