<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration Condition="'$(Configuration)' == ''">Release</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProjectGuid>{bc50d376-ac6b-460d-b485-0ce90c2a4565}</ProjectGuid>
    <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{656346D9-4656-40DA-A068-22D5425D4639}</ProjectTypeGuids>
    <OutputType>Library</OutputType>
    <RootNamespace>RemObjects.Script</RootNamespace>
    <AssemblyName>RemObjects.Script.Silverlight</AssemblyName>
    <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <SilverlightVersion>v5.0</SilverlightVersion>
    <SilverlightApplication>false</SilverlightApplication>
    <ValidateXaml>true</ValidateXaml>
    <ThrowErrorsInValidation>true</ThrowErrorsInValidation>
    <AllowGlobals>False</AllowGlobals>
    <AllowLegacyOutParams>False</AllowLegacyOutParams>
    <AllowLegacyCreate>False</AllowLegacyCreate>
    <Name>RemObjects.Script.Silverlight</Name>
    <Company>RemObjects Software, Inc.</Company>
    <InternalAssemblyName />
    <StartupClass />
    <DefaultUses />
    <ApplicationIcon />
    <TargetFrameworkProfile />
  </PropertyGroup>
  <!-- This property group is only here to support building this project using the
       MSBuild 3.5 toolset. In order to work correctly with this older toolset, it needs
       to set the TargetFrameworkVersion to v3.5 -->
  <PropertyGroup Condition="'$(MSBuildToolsVersion)' == '3.5'">
    <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <DefineConstants>DEBUG;TRACE;SILVERLIGHT</DefineConstants>
    <OutputPath>..\..\Bin\Silverlight\</OutputPath>
    <GeneratePDB>True</GeneratePDB>
    <Optimize>False</Optimize>
    <GenerateMDB>True</GenerateMDB>
    <SuppressWarnings />
    <CpuType>anycpu</CpuType>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <FutureHelperClassName />
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <DefineConstants>SILVERLIGHT</DefineConstants>
    <OutputPath>..\..\Bin\Silverlight\</OutputPath>
    <EnableAsserts>False</EnableAsserts>
    <SuppressWarnings />
    <CpuType>anycpu</CpuType>
    <XmlDocWarningLevel>WarningOnPublicMembers</XmlDocWarningLevel>
    <FutureHelperClassName />
    <GeneratePDB>True</GeneratePDB>
    <GenerateMDB>True</GenerateMDB>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="mscorlib" />
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Net" />
  </ItemGroup>
  <ItemGroup>
    <Compile Include="Common.pas" />
    <Compile Include="EcmaScript\Bindings\AdditiveOperators.pas" />
    <Compile Include="EcmaScript\Bindings\BitwiseOperators.pas" />
    <Compile Include="EcmaScript\Bindings\MultiplicativeOperators.pas" />
    <Compile Include="EcmaScript\Bindings\Operators.pas" />
    <Compile Include="EcmaScript\Bindings\PrePostfixOperators.pas" />
    <Compile Include="EcmaScript\Bindings\RelationalOperators.pas" />
    <Compile Include="EcmaScript\Bindings\ShiftOperators.pas" />
    <Compile Include="EcmaScript\Bindings\UnaryOperators.pas" />
    <Compile Include="EcmaScript\LanguageContext.pas" />
    <Compile Include="EcmaScript\Objects\Argument.pas" />
    <Compile Include="EcmaScript\Objects\Array.pas" />
    <Compile Include="EcmaScript\Objects\Boolean.pas" />
    <Compile Include="EcmaScript\Objects\Date.pas" />
    <Compile Include="EcmaScript\Objects\Debug.pas" />
    <Compile Include="EcmaScript\Objects\DefaultObjects.pas" />
    <Compile Include="EcmaScript\Objects\Error.pas" />
    <Compile Include="EcmaScript\Objects\Function.pas" />
    <Compile Include="EcmaScript\Objects\JSON.pas" />
    <Compile Include="EcmaScript\Objects\Math.pas" />
    <Compile Include="EcmaScript\Objects\Number.pas" />
    <Compile Include="EcmaScript\Objects\Object.pas" />
    <Compile Include="EcmaScript\Objects\RegExp.pas" />
    <Compile Include="EcmaScript\Objects\String.pas" />
    <Compile Include="EcmaScript\Objects\Utilities.pas" />
    <Compile Include="EcmaScript\Parser.pas" />
    <Compile Include="EcmaScript\ParserClasses.pas" />
    <Compile Include="EcmaScript\Scope.pas">
    </Compile>
    <Compile Include="EcmaScript\Tokenizer.pas" />
    <None Include="PascalScript\LanguageContext.pas" />
    <Compile Include="EcmaScript\Wrappers.pas" />
    <Compile Include="PascalScript\Parser.pas" />
    <Compile Include="PascalScript\ParserClasses.pas" />
    <Compile Include="PascalScript\Tokenizer.pas" />
    <Compile Include="Properties\AssemblyInfo.pas" />
    <EmbeddedResource Include="Properties\Resources.resx">
      <Generator>ResXFileCodeGenerator</Generator>
    </EmbeddedResource>
    <Compile Include="Properties\Resources.Designer.pas" />
    <Compile Include="ScriptComponent.pas">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </Compile>
  </ItemGroup>
  <ItemGroup>
    <Folder Include="EcmaScript\" />
    <Folder Include="EcmaScript\Bindings\" />
    <Folder Include="EcmaScript\Objects\" />
    <Folder Include="Glyphs\" />
    <Folder Include="PascalScript\" />
    <Folder Include="Properties\" />
  </ItemGroup>
  <ItemGroup>
    <EmbeddedResource Include="Glyphs\EcmaScriptComponent.png">
      <SubType>Content</SubType>
    </EmbeddedResource>
  </ItemGroup>
  <Import Project="$(MSBuildExtensionsPath)\RemObjects Software\Oxygene\RemObjects.Oxygene.Echoes.Silverlight.targets" />
  <ProjectExtensions />
</Project>
