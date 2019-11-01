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
WSO2 API Manager is a complete solution for designing and publishing APIs, creating and managing a developer
community, and for securing and routing API traffic in a scalable manner. It leverages proven components from
the WSO2 platform to secure, integrate and manage APIs. In addition, it integrates with the WSO2 analytics
platform and provides out of the box reports and alerts, giving you instant insights into the APIs behavior.

%prep
# clear BUILD directory and copy source files to BUILD directory
echo "Preparing WSO2 API Manager installation..."
rm -rf %{_topdir}/BUILD/*
cp -r %{_topdir}/SOURCES/%{name}-%{version}/* %{_topdir}/BUILD/

%build

%pre
echo "Installing WSO2 API Manager %{version}..."

%install
rm -rf $RPM_BUILD_ROOT
install -d %{buildroot}%{_libdir}/wso2/%{name}/%{version}
cp -r ./* %{buildroot}%{_libdir}/wso2/%{name}/%{version}

%post
echo "Creating shortcuts for name profiles..."
ln -sf %{_libdir}/wso2/%{name}/%{version}/bin/launcher_wso2server.sh /usr/bin/%{name}-%{version}
# add wso2 user and group
echo "Creating wso2 user and group..."
sudo groupadd --system wso2 >/dev/null
sudo useradd --system --create-home --home-dir /home/wso2 -g wso2 wso2 >/dev/null
# change wso2 user's password
sudo echo wso2:wso2 | sudo chpasswd >/dev/null
#change the installed directory ownership
sudo chown -R wso2:wso2 /usr/lib64/wso2/%{name}/%{version}/
# copy service script files
echo "Initializing service script file..."
sudo mv /usr/lib64/wso2/%{name}/%{version}/%{name}-%{version} /etc/init.d/
sudo chown root:root /etc/init.d/%{name}-%{version}
# update rc service
sudo systemctl daemon-reload
echo ". . ."
echo "WSO2 API Manager Installed on : \"/usr/lib64/wso2/%{name}/%{version}/\""
echo "To run WSO2 API Manager as a service, open a new terminal and run:"
echo "     $ sudo service %{name}-%{version} start"
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
