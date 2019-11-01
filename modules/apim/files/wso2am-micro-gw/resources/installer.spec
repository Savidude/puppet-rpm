Name:           __PRODUCT__
Version:        __VERSION__
Release:        1%{?dist}
Summary:        WSO2 %{name} %{version} name
License:        Apache license 2.0
URL:            https://www.wso2.com/api-management/
Packager:       WSO2 Inc. <admin@wso2.com>

# Disable Automatic Dependencies
AutoReqProv: no
# Override RPM file name
%define _rpmfilename %%{ARCH}/%{name}-linux-installer-x64-%{version}.rpm
# Disable Jar repacking
%define __jar_repack %{nil}

%description
The WSO2 API Microgateway is a lightweight message processor for APIs.
The Microgateway is used for message security, transport security, routing,
and other common API Management related quality of services.
It can process incoming and outgoing messages while collecting information required for usage metering
and throttling capabilities. The Microgateway natively supports scaling in highly decentralized environments
including microservice architecture.
An immutable, ephemeral Microgateway fits well with the microservice architecture.
The Microgateway is also capable of operating in lockdown environments such as IoT devices,
since connectivity from the Microgateway to the API Management system is not mandatory.

%prep
# clear BUILD directory and copy source files to BUILD directory
echo "Preparing WSO2 APIM Microgateway installation..."
rm -rf %{_topdir}/BUILD/*
cp -r %{_topdir}/SOURCES/%{name}-%{version}/* %{_topdir}/BUILD/

%build

%pre
echo "Installing WSO2 APIM Microgateway %{version}..."

%install
rm -rf $RPM_BUILD_ROOT
install -d %{buildroot}%{_libdir}/wso2/%{name}/%{version}
cp -r ./* %{buildroot}%{_libdir}/wso2/%{name}/%{version}

%post
echo "Creating shortcuts for name profiles..."
ln -sf %{_libdir}/wso2/%{name}/%{version}/bin/gateway /usr/bin/%{name}-%{version}
# add wso2 user and group
echo "Creating wso2 user and group..."
sudo groupadd --system wso2 >/dev/null
sudo useradd --system --create-home --home-dir /home/wso2 -g wso2 wso2 >/dev/null
#change the installed directory ownership
sudo chown -R wso2:wso2 /usr/lib64/wso2/%{name}/%{version}/
# copy service script files
echo "Initializing service script file..."
sudo mv /usr/lib64/wso2/%{name}/%{version}/%{name}-%{version} /etc/init.d/
sudo chown root:root /etc/init.d/%{name}-%{version}
# update rc service
sudo systemctl daemon-reload
echo ". . ."
echo "WSO2 APIM Microgateway Installed on : \"/usr/lib64/wso2/%{name}/%{version}/\""
echo "To run WSO2 APIM Microgateway, open a new terminal and run:"
echo "     $ sudo %{name}-%{version} <Path_to_Executable_Artifact>"
echo "Note: Executable artifact(.balx) is created using microgateway toolkit when project is built."
echo ". . ."

%postun
echo "Deleting service script file..."
sudo rm -rf /etc/init.d/%{name}-%{version}
echo "Deleting name shortcut..."
if [ -L /usr/bin/%{name}-%{version} ]; then
	sudo rm -f /usr/bin/%{name}-%{version}
fi
if [ -d /usr/lib64/wso2/%{name}/%{version}/ ]
then
	echo "Removing configuration files..."
	sudo rm -rf /usr/lib64/wso2/%{name}/%{version}/
	dirCount=0
	for directory in /usr/lib64/wso2/%{name}/*;
	do
	  if [ -d "$directory" ]; then
	    dirCount=$((dirCount+1))
	  fi
	done
	if [ "$dirCount" = 0 ] ; then
	 	sudo rm -rf /usr/lib64/wso2/%{name}/
	fi
fi

%clean
rm -rf %{_topdir}/BUILD/*
rm -rf %{buildroot}

%files
%{_libdir}/wso2/%{name}/%{version}
