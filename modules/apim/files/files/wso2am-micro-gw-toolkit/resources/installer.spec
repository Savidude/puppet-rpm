Name:           __PRODUCT__
Version:        __VERSION__
Release:        1%{?dist}
Summary:        WSO2 %{name} %{version}
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
WSO2 API Microgateway itself performs all the functionality without calling the other servers, 
which considerably reduces the average response time to serve an API call. 
The toolkit is used to initiate microgateway projects. Once the project is initialized 
API developer can add(copy) open API definitions of the APIs to the project or import APIs from WSO2 API Manager. 
Once all the APIs are added the toolkit can be used to build the project and create and executable file.

%prep
# clear BUILD directory and copy source files to BUILD directory
echo "Preparing WSO2 APIM Microgateway Toolkit installation..."
rm -rf %{_topdir}/BUILD/*
cp -r %{_topdir}/SOURCES/%{name}-%{version}/* %{_topdir}/BUILD/

%build

%pre
echo "Installing WSO2 APIM Microgateway Toolkit %{version}..."

%install
rm -rf $RPM_BUILD_ROOT
install -d %{buildroot}%{_libdir}/wso2/%{name}/%{version}
cp -r ./* %{buildroot}%{_libdir}/wso2/%{name}/%{version}

%post
echo "Creating shortcuts for name profiles..."
ln -sf %{_libdir}/wso2/%{name}/%{version}/bin/launcher_micro-gw.sh /usr/bin/micro-gw
# add wso2 user and group
echo "Creating wso2 user and group..."
sudo groupadd --system wso2 >/dev/null
sudo useradd --system --create-home --home-dir /home/wso2 -g wso2 wso2 >/dev/null
# change ownership to wso2 user and group of neededful directories
sudo chown -R wso2:wso2 %{_libdir}/wso2/%{name}/%{version}/
# give write access to wso2 group members for neededful directories
sudo chmod 775 %{_libdir}/wso2/%{name}/%{version}/logs/
sudo chmod 775 %{_libdir}/wso2/%{name}/%{version}/lib/
echo "WSO2 APIM Microgateway Installed on : \"/usr/lib64/wso2/%{name}/%{version}/\""
echo ""
echo " The WSO2 APIM Micro-gateway Toolkit is installed with 'wso2' user of 'wso2' group. If you wish to access using a different user, please add the new user to the 'wso2' group."
echo "    1. Add your user to the wso2 group."
echo "        $ sudo usermod -aG wso2 \$USER"
echo "    2. Log out and log back in so that your group membership is re-evaluated."
echo "    3. To run WSO2 APIM Micro-gateway Toolkit commands, open a new terminal and run:"
echo "        $ micro-gw <COMMAND>"
echo ""

%postun
echo "Deleting service script file..."
sudo rm -rf /etc/init.d/%{name}-%{version}
echo "Deleting name shortcut..."
if [ -L /usr/bin/%{name}-%{version} ]; then
	sudo rm -f /usr/bin/micro-gw
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
