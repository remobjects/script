<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="Build" ToolsVersion="4.0">
    <PropertyGroup>
        <ProductVersion>3.5</ProductVersion>
        <OutputType>Library</OutputType>
        <AssemblyName>RemObjects.Script</AssemblyName>
        <AllowGlobals>False</AllowGlobals>
        <AllowLegacyOutParams>False</AllowLegacyOutParams>
        <AllowLegacyCreate>False</AllowLegacyCreate>
        <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
        <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
        <ProjectGuid>{CAF9C919-D826-4452-910E-D8BA4861CD72}</ProjectGuid>
        <RootNamespace>RemObjects.Script</RootNamespace>
        <RunPostBuildEvent>OnBuildSuccess</RunPostBuildEvent>
        <Company>RemObjects Software, Inc.</Company>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Debug' ">
        <DefineConstants>DESIGN;DEBUG;TRACE;</DefineConstants>
        <OutputPath>..\..\Bin\</OutputPath>
        <GeneratePDB>True</GeneratePDB>
        <GenerateMDB>True</GenerateMDB>
        <SuppressWarnings/>
        <CpuType>anycpu</CpuType>
        <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
        <FutureHelperClassName/>
        <EnableUnmanagedDebugging>True</EnableUnmanagedDebugging>
        <DebugClass/>
        <AssertMethodName/>
        <WarnOnCaseMismatch>True</WarnOnCaseMismatch>
    </PropertyGroup>
    <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">
        <DefineConstants>DESIGN</DefineConstants>
        <OutputPath>..\..\Bin</OutputPath>
        <EnableAsserts>False</EnableAsserts>
        <DefineConstants/>
        <SuppressWarnings/>
        <CodeFlowAnalysis>True</CodeFlowAnalysis>
        <CpuType>anycpu</CpuType>
        <TreatWarningsAsErrors>False</TreatWarningsAsErrors>
        <RegisterForComInterop>False</RegisterForComInterop>
        <UseXmlDoc>False</UseXmlDoc>
        <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
        <XmlDocAllMembers>False</XmlDocAllMembers>
        <Optimize>True</Optimize>
        <GeneratePDB>True</GeneratePDB>
        <GenerateMDB>True</GenerateMDB>
        <WarnOnCaseMismatch>False</WarnOnCaseMismatch>
        <RunCodeAnalysis>False</RunCodeAnalysis>
        <RequireExplicitLocalInitialization>False</RequireExplicitLocalInitialization>
        <FutureHelperClassName/>
    </PropertyGroup>
    <ItemGroup>
        <Reference Include="mscorlib"/>
        <Reference Include="System"/>
        <Reference Include="System.Core">
            <HintPath>C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\v3.5\System.Core.dll</HintPath>
        </Reference>
        <Reference Include="System.Data"/>
        <Reference Include="System.Drawing"/>
        <Reference Include="System.Windows.Forms"/>
        <Reference Include="System.Xml"/>
        <Reference Include="System.Xml.Linq"/>
    </ItemGroup>
    <ItemGroup>
        <Compile Include="Common.pas"/>
        <Compile Include="EcmaScript\Bindings\AdditiveOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\BitwiseOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\MultiplicativeOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\Operators.pas"/>
        <Compile Include="EcmaScript\Bindings\PrePostfixOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\RelationalOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\ShiftOperators.pas"/>
        <Compile Include="EcmaScript\Bindings\UnaryOperators.pas"/>
        <Compile Include="EcmaScript\LanguageContext.pas"/>
        <Compile Include="EcmaScript\Objects\Argument.pas"/>
        <Compile Include="EcmaScript\Objects\Array.pas"/>
        <Compile Include="EcmaScript\Objects\Boolean.pas"/>
        <Compile Include="EcmaScript\Objects\Date.pas"/>
        <Compile Include="EcmaScript\Objects\Debug.pas"/>
        <Compile Include="EcmaScript\Objects\DefaultObjects.pas"/>
        <Compile Include="EcmaScript\Objects\Error.pas"/>
        <Compile Include="EcmaScript\Objects\Function.pas"/>
        <Compile Include="EcmaScript\Objects\JSON.pas"/>
        <Compile Include="EcmaScript\Objects\Math.pas"/>
        <Compile Include="EcmaScript\Objects\Number.pas"/>
        <Compile Include="EcmaScript\Objects\Object.pas"/>
        <Compile Include="EcmaScript\Objects\RegExp.pas"/>
        <Compile Include="EcmaScript\Objects\String.pas"/>
        <Compile Include="EcmaScript\Objects\Utilities.pas"/>
        <Compile Include="EcmaScript\Parser.pas"/>
        <Compile Include="EcmaScript\ParserClasses.pas"/>
        <Compile Include="EcmaScript\Scope.pas"/>
        <Compile Include="EcmaScript\Tokenizer.pas"/>
        <None Include="PascalScript\LanguageContext.pas"/>
        <Compile Include="EcmaScript\Wrappers.pas"/>
        <Compile Include="PascalScript\Parser.pas"/>
        <Compile Include="PascalScript\ParserClasses.pas"/>
        <Compile Include="PascalScript\Tokenizer.pas"/>
        <Compile Include="Properties\AssemblyInfo.pas"/>
        <EmbeddedResource Include="Properties\Resources.resx">
            <Generator>ResXFileCodeGenerator</Generator>
        </EmbeddedResource>
        <Compile Include="Properties\Resources.Designer.pas"/>
        <None Include="Properties\Settings.settings">
            <Generator>SettingsSingleFileGenerator</Generator>
        </None>
        <Compile Include="Properties\Settings.Designer.pas"/>
        <Compile Include="ScriptComponent.pas">
            <CopyToOutputDirectory>Never</CopyToOutputDirectory>
        </Compile>
    </ItemGroup>
    <ItemGroup>
        <Folder Include="EcmaScript\"/>
        <Folder Include="EcmaScript\Bindings\"/>
        <Folder Include="EcmaScript\Objects\"/>
        <Folder Include="Glyphs\"/>
        <Folder Include="PascalScript\"/>
        <Folder Include="Properties\"/>
    </ItemGroup>
    <ItemGroup>
        <Content Include="EcmaScript\EcmaScriptComponent.png">
            <SubType>Content</SubType>
        </Content>
        <Content Include="Glyphs\EcmaScriptComponent.png">
            <SubType>Content</SubType>
        </Content>
    </ItemGroup>
    <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Elements\RemObjects.Elements.Echoes.targets"/>
    <PropertyGroup>
        <PreBuildEvent/>
    </PropertyGroup>
</Project>