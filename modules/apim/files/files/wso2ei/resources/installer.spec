Name:           __PRODUCT__
Version:        __VERSION__
Release:        1%{?dist}
Summary:        WSO2 %{name} %{version} name
License:        Apache license 2.0
URL:            https://www.wso2.com/integration/
Packager:       WSO2 Inc. <admin@wso2.com>

# Disable Automatic Dependencies
AutoReqProv: no
# Override RPM file name
%define _rpmfilename %%{ARCH}/%{name}-linux-installer-x64-%{version}.rpm
# Disable Jar repacking
%define __jar_repack %{nil}

%description
Integration is at the heart of any digital transformation. By connecting different systems that make up your enterprise, 
you can build an organization that acts as one seamless digital system. WSO2 Enterprise Integrator (EI) is an open source product 
that enables comprehensive integration for cloud native and container-native projects.

%prep
# clear BUILD directory and copy source files to BUILD directory
echo "Preparing WSO2 EI installation..."
rm -rf %{_topdir}/BUILD/*
cp -r %{_topdir}/SOURCES/%{name}-%{version}/* %{_topdir}/BUILD/

%build

%pre
echo "Installing WSO2 Enterprise Integrator %{version}..."

%install
rm -rf $RPM_BUILD_ROOT
install -d %{buildroot}%{_libdir}/wso2/%{name}/%{version}
cp -r ./* %{buildroot}%{_libdir}/wso2/%{name}/%{version}

#case for
%post
echo "Creating shortcuts for name profiles..."
ln -sf %{_libdir}/wso2/%{name}/%{version}/streaming-integrator/bin/launcher_server.sh /usr/bin/wso2si
ln -sf %{_libdir}/wso2/%{name}/%{version}/ballerina-integrator/bin/ballerina /usr/bin/ballerina
ln -sf %{_libdir}/wso2/%{name}/%{version}/micro-integrator/bin/launcher_micro-integrator.sh /usr/bin/wso2mi
# set ballerina home
echo "export BALLERINA_HOME=%{_libdir}/wso2/%{name}/%{version}/ballerina-integrator/" >> /etc/profile.d/wso2.sh
# add wso2 user and group
echo "Creating wso2 user and group..."
sudo groupadd --system wso2 >/dev/null
sudo useradd --system --create-home --home-dir /home/wso2 -g wso2 wso2 >/dev/null
#change the installed directory ownership
sudo chown -R wso2:wso2 /usr/lib64/wso2/%{name}/%{version}/
# copy service script files
echo "Initializing service script file..."
sudo mv /usr/lib64/wso2/%{name}/%{version}/wso2si /etc/init.d/
sudo mv /usr/lib64/wso2/%{name}/%{version}/wso2mi /etc/init.d/
sudo chown root:root /etc/init.d/wso2*
# update rc service
sudo systemctl daemon-reload
echo ". . ."
echo "WSO2 Enterprise Integrator installed on : \"/usr/lib64/wso2/%{name}/%{version}/\""
echo "To run WSO2 Ballerina, open a new terminal and run:"
echo "     $ ballerina"
echo "To start WSO2 Micro Integrator as a service, open a new terminal and run:"
echo "     $ sudo service wso2mi start"
echo "To start WSO2 Streaming Integrator as a service, open a new terminal and run:"
echo "     $ sudo service wso2si start"
echo ". . ."

%postun
echo "Deleting service script file..."
sudo rm -rf /etc/init.d/wso2*
echo "Deleting name shortcut..."
if [ -L /usr/bin/wso2si ]; then
	sudo rm -f /usr/bin/wso2si
fi
if [ -L /usr/bin/ballerina ]; then
	sudo rm -f /usr/bin/ballerina
fi
if [ -L /usr/bin/wso2mi ]; then
	sudo rm -f /usr/bin/wso2mi
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
