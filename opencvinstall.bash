#! /usr/bin/env bash
#
# Install script for OpenCV
#
# Script dependencies:
#   1) version - Text file containing the version of OpenCV to be installed
#
# Supported systems:
#   1) Ubuntu 16.04
#   2) Raspbian Stretch
#
# Supported programming languages:
#   1) Python3
#   2) C++
#
# Contributors:
#   2018-08-22 Arpit Aggarwal


VERSION="$(cat version)"
DEVICE="$(grep Hardware /proc/cpuinfo)"

usage()
{
    echo "--------------------------------------------------------------------------"
    echo "              OpenCV $VERSION Installation"
    echo "--------------------------------------------------------------------------"
    echo "Create a version file with the version of OpenCV to be installed in it"
    echo "Example:  echo \"3.4.2\" > version "
    echo
    echo "Install OpenCV using opencvinstall.bash"
    echo "Usage: ./opencvinstall.bash [options]"
    echo -e "options:\n \
    -h | --help\n \
    --install-complete\n \
    --install-dependencies\n \
    --install-asterisk\n \
    --install-pri-support\n \
    --check-install"
    echo
}

if [ -z "$VERSION" ]; then
    echo "version file not found"
    echo
    usage
    exit
fi

echo
echo "--------------------------------------------------------------------------"
echo "              OpenCV $VERSION Installation"
echo "--------------------------------------------------------------------------"
echo

install_dependencies()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Installing dependencies"
    echo "--------------------------------------------------------------------------"
    echo

    sudo apt-get update
    sudo apt-get upgrade --assume-yes

    sudo apt-get install --assume-yes build-essential cmake git vim
    sudo apt-get install --assume-yes pkg-config unzip ffmpeg python3-dev gfortran python3-pip
    sudo apt-get install --assume-yes libgtk-3-dev libdc1394-22 libdc1394-22-dev libjpeg-dev libpng12-dev libtiff5-dev libjasper-dev
    sudo apt-get install --assume-yes libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev
    sudo apt-get install --assume-yes libv4l-dev libtbb-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev
    sudo apt-get install --assume-yes libvorbis-dev libxvidcore-dev v4l-utils vtk6 libx264-dev
    sudo apt-get install --assume-yes liblapacke-dev libopenblas-dev libgdal-dev checkinstall
    sudo apt-get install --assume-yes libeigen3-dev libatlas-base-dev
}

download_opencv()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Downloading and extracting OpenCV-$VERSION "
    echo "--------------------------------------------------------------------------"
    echo

    wget -O opencv-"${VERSION}".zip https://github.com/opencv/opencv/archive/"${VERSION}".zip opencv-"${VERSION}".zip
    unzip opencv-"${VERSION}".zip && rm opencv-"${VERSION}".zip

    echo
    echo "--------------------------------------------------------------------------"
    echo "              Downloading and extracting OpenCV-contrib-$VERSION"
    echo "--------------------------------------------------------------------------"
    echo

    wget -O opencv_contrib-"${VERSION}".zip https://github.com/opencv/opencv_contrib/archive/"${VERSION}".zip
    unzip opencv_contrib-"${VERSION}" && rm opencv_contrib-"${VERSION}".zip
}


install_virtualenv()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Installing virtualenv and setting up (cv) venv"
    echo "--------------------------------------------------------------------------"
    echo


    sudo pip3 install -U pip
    sudo pip3 install virtualenv
    sudo rm -rf ~/.cache/pip

    if [ ! -d ~/.venvs ]; then
        mkdir ~/.venvs
    fi

    cd ~/.venvs
    virtualenv --system-site-packages -p python3 cv
    cd ~
    echo "alias cv='source ~/.venvs/cv/bin/activate && PYTHONPATH='" >> ~/.bash_aliases
    source ~/.bashrc
    source ~/.venvs/cv/bin/activate
    export PYTHONPATH=

    pip install -U pip
    pip install numpy
    pip install matplotlib
    pip install ipython
}


config_cmake()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Configuring OpenCV-$VERSION build"
    echo "--------------------------------------------------------------------------"
    echo

    cd opencv-"${VERSION}"
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=~/.venvs/cv \
        -D INSTALL_PYTHON_EXAMPLES=ON \
        -D INSTALL_C_EXAMPLES=OFF \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib-"${VERSION}"/modules \
        -D PYTHON_EXECUTABLE=~/.venvs/cv/bin/python \
        -D BUILD_EXAMPLES=ON ..

    echo
    echo "--------------------------------------------------------------------------"
    echo "  !!! DO NOT FORGET TO EXAMINE THE OUTPUT OF CMAKE BEFORE CONTINUING !!!"
    echo "--------------------------------------------------------------------------"
    echo
}


make_opencv()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Building OpenCV-$VERSION"
    echo "--------------------------------------------------------------------------"
    echo

    if [ "$DEVICE" = "Hardware   : BCM2835" ]; then
        sudo sed -i "s/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/g" /etc/dphys-swapfile
        sudo systemctl restart dphys-swapfile
    fi

    make -j $(($(nproc) + 1))
    
    if [ "$DEVICE" = "Hardware   : BCM2835" ]; then
        sudo sed -i "s/CONF_SWAPSIZE=1024/CONF_SWAPSIZE=100/g" /etc/dphys-swapfile
        sudo systemctl restart dphys-swapfile
    fi
}

install_opencv()
{
    make install
    sudo ldconfig
}


check_install()
{
    echo
    echo "--------------------------------------------------------------------------"
    echo "              Checking installation"
    echo "--------------------------------------------------------------------------"
    echo

    CVV="$(python -c "import cv2; print(cv2.__version__)")"

    if [ "$CVV" != "$VERSION" ]; then
        echo "Installation failure"
    else
        echo "OpenCV-$VERSION successfully installed"
    fi
}

install_complete()
{
    install_dependencies
    download_opencv    
    install_virtualenv
    config_cmake
    
    read -n1 -rsp $'Press space to continue...\n' key
    while [ "$key" != '' ]; do
        :
    done
    
    make_opencv
    install_opencv
    check_install
}

# Read Postional Parameters
if [ -z "$1" ]; then
        install_complete
else
    while [ "$1" != "" ]; do
        case $1 in
            --install-dependencies )
                install_dependencies ;;
            
            --download-opencv )
                download_opencv ;;

            --install-virtualenv )
                install_virtualenv ;;

            --config-cmake )
                config_cmake ;;

            --make-opencv )
                make_opencv ;;

            --install-opencv )
                install_opencv ;;
            
            --check-install )
                check_install;;
            
            --h | --help )
                usage
                exit;;

            * )
                usage
                exit 1;;
        esac
        shift
    done
fi

