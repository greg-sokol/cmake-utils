# vim: ts=2 sw=2
# - Try to find the required ffmpeg components(default: AVFORMAT, AVUTIL, AVCODEC)
#
# - If ffmpeg components are installed in a nonstandard location the following hints can be
# defined
#   - ENV{PKG_CONFIG_PATH} - to point to a directory containing the .pc file
#   - FFMPEG_INCLUDE_DIR - to point to the include directory
#   - FFMPEG_LIBRARY_DIR - to point to the directory containing libraries
#
# - Static linking is supported. If pkgconfig file is found all the dependencies will be
# listed in link order. When only FFMPEG_INCLUDE_DIR and FFMPEG_LIBRARY_DIR are defined
# one must include those dependencies (like -lm, -lz or -lx264) manually in CMakeLists.txt
#
# Once done this will define
#  FFMPEG_FOUND         - System has the all required components.
#  FFMPEG_INCLUDE_DIRS  - Include directory necessary for using the required components headers.
#  FFMPEG_LIBRARIES     - Link these to use the required ffmpeg components.
#  FFMPEG_DEFINITIONS   - Compiler switches required for using the required ffmpeg components.
#
# For each of the components it will additionally set.
#   - AVCODEC
#   - AVDEVICE
#   - AVFORMAT
#   - AVFILTER
#   - AVUTIL
#   - POSTPROC
#   - SWSCALE
# the following variables will be defined
#  <component>_FOUND        - System has <component>
#  <component>_INCLUDE_DIRS - Include directory necessary for using the <component> headers
#  <component>_LIBRARIES    - Link these to use <component>
#  <component>_DEFINITIONS  - Compiler switches required for using <component>
#  <component>_VERSION      - The components version
#
# Copyright (c) 2006, Matthias Kretz, <kretz@kde.org>
# Copyright (c) 2008, Alexander Neundorf, <neundorf@kde.org>
# Copyright (c) 2011, Michael Jansen, <kde@michael-jansen.biz>
# Copyright (c) 2021, Grzegorz Sokol, <gs@grzegorzsokol.name>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

include(FindPackageHandleStandardArgs)

# The default components were taken from a survey over other FindFFMPEG.cmake files
if (NOT FFmpeg_FIND_COMPONENTS)
  set(FFmpeg_FIND_COMPONENTS AVFORMAT AVCODEC SWRESAMPLE AVUTIL)
endif ()

#
### Macro: set_component_found
#
# Marks the given component as found if both *_LIBRARIES AND *_INCLUDE_DIRS is present.
#
macro(set_component_found _component )
  if (${_component}_LIBRARIES AND ${_component}_INCLUDE_DIRS)
    #message(STATUS "  - ${_component} found.")
    set(${_component}_FOUND TRUE)
  else ()
    #message(STATUS "  - ${_component} not found.")
  endif ()
endmacro()

#
### Macro: find_component
#
# Checks for the given component by invoking pkgconfig and then looking up the libraries and
# include directories.
#
macro(find_component _component _pkgconfig _library _header)

  if (NOT WIN32)
     # use pkg-config to get the directories and then use these values
     # in the FIND_PATH() and FIND_LIBRARY() calls
     find_package(PkgConfig)
     if (PKG_CONFIG_FOUND)
       pkg_check_modules(PC_${_component} ${_pkgconfig})
     endif ()
  endif (NOT WIN32)

  find_path(${_component}_INCLUDE_DIRS_TMP ${_header}
    HINTS
      ${PC_${_component}_INCLUDEDIR}
      ${PC_${_component}_INCLUDE_DIRS}
      ${FFMPEG_INCLUDE_DIR}
  )

  find_library(${_component}_LIBRARIES_TMP NAMES ${_library}
      HINTS
      ${PC_${_component}_LIBDIR}
      ${PC_${_component}_LIBRARY_DIRS}
      ${FFMPEG_LIBRARY_DIR}
  )

  if (${_component}_LIBRARIES_TMP)
      get_filename_component(_LIBDIRS "${${_component}_LIBRARIES_TMP}" DIRECTORY BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
      set(${_component}_LIBRARY_DIRS "${_LIBDIRS}" CACHE STRING "The ${_component} LIBDIRS." FORCE)
      if (PC_${_component}_LIBRARIES)
          set(${_component}_LIBRARIES ${PC_${_component}_LIBRARIES} CACHE STRING "The ${_component} LIBS." FORCE)
      else(PC_${_component}_LIBRARIES)
          set(${_component}_LIBRARIES ${_library} CACHE STRING "The ${_component} LIBS." FORCE)
      endif(PC_${_component}_LIBRARIES)

      list(REMOVE_DUPLICATES ${_component}_LIBRARIES)

      #message("${_component}_LIBRARIES_TMP " "${${_component}_LIBRARIES_TMP}")
      #message("${_component}_LIBRARIES " "${${_component}_LIBRARIES}")
      #message("${_component}_LIBRARY_DIRS " "${${_component}_LIBRARY_DIRS}")
      #message("${_component}_FOUND " "${${_component}_FOUND}")

      set(${_component}_INCLUDE_DIRS ${${_component}_INCLUDE_DIRS_TMP} CACHE STRING "The ${_component} INCLUDES.")
      set(${_component}_DEFINITIONS  ${PC_${_component}_CFLAGS_OTHER} CACHE STRING "The ${_component} CFLAGS.")
      set(${_component}_VERSION      ${PC_${_component}_VERSION}      CACHE STRING "The ${_component} version number.")

      set(${_component}_FOUND TRUE)

  endif(${_component}_LIBRARIES_TMP)

  mark_as_advanced(
    ${_component}_INCLUDE_DIRS
    ${_component}_LIBRARIES
    ${_component}_DEFINITIONS
    ${_component}_LIBRARY_DIRS
    ${_component}_VERSION)
endmacro()


# Check for cached results. If there are skip the costly part.
if (NOT FFMPEG_LIBRARIES)

  # Check for all possible component.

  find_component(POSTPROC   libpostproc   postproc libpostproc/postprocess.h)
  find_component(AVDEVICE   libavdevice   avdevice libavdevice/avdevice.h)
  find_component(AVFILTER   libavfilter   avfilter libavfilter/avfilter.h)
  find_component(AVFORMAT   libavformat   avformat libavformat/avformat.h)
  find_component(AVCODEC    libavcodec    avcodec  libavcodec/avcodec.h)
  find_component(SWRESAMPLE libswresample swresample libswresample/swresample.h)
  find_component(SWSCALE    libswscale    swscale  libswscale/swscale.h)
  find_component(AVUTIL     libavutil     avutil   libavutil/avutil.h)

  # Check if the required components were found and add their stuff to the FFMPEG_* vars.
  foreach (_component ${FFmpeg_FIND_COMPONENTS})
    if (${_component}_FOUND)
      # message(STATUS "Required component ${_component} present.")
      set(FFMPEG_LIBRARIES   ${FFMPEG_LIBRARIES}   ${${_component}_LIBRARIES})
      set(FFMPEG_DEFINITIONS ${FFMPEG_DEFINITIONS} ${${_component}_DEFINITIONS})
      set(FFMPEG_LIBRARY_DIRS ${FFMPEG_LIBRARY_DIRS} ${${_component}_LIBRARY_DIRS})
      list(APPEND FFMPEG_INCLUDE_DIRS ${${_component}_INCLUDE_DIRS})
    else ()
      # message(STATUS "Required component ${_component} missing.")
    endif ()
  endforeach ()

  # Build the include path with duplicates removed.
  if (FFMPEG_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES FFMPEG_INCLUDE_DIRS)
  endif (FFMPEG_INCLUDE_DIRS)

  if (FFMPEG_LIBRARIES)
      list(REMOVE_DUPLICATES FFMPEG_LIBRARIES)
  endif(FFMPEG_LIBRARIES)

  if (FFMPEG_LIBRARY_DIRS)
      list(REMOVE_DUPLICATES FFMPEG_LIBRARY_DIRS)
  endif(FFMPEG_LIBRARY_DIRS)

  # cache the vars.
  set(FFMPEG_INCLUDE_DIRS ${FFMPEG_INCLUDE_DIRS} CACHE STRING "The FFmpeg include directories." FORCE)
  set(FFMPEG_LIBRARIES    ${FFMPEG_LIBRARIES}    CACHE STRING "The FFmpeg libraries." FORCE)
  set(FFMPEG_DEFINITIONS  ${FFMPEG_DEFINITIONS}  CACHE STRING "The FFmpeg cflags." FORCE)
  set(FFMPEG_LIBRARY_DIRS ${FFMPEG_LIBRARY_DIRS}  CACHE STRING "The FFmpeg libdirs." FORCE)

  mark_as_advanced(FFMPEG_INCLUDE_DIRS
                   FFMPEG_LIBRARIES
                   FFMPEG_DEFINITIONS
                   FFMPEG_LIBRARY_DIRS)
endif ()

# Now set the noncached _FOUND vars for the components.
foreach (_component AVCODEC AVDEVICE AVFORMAT AVUTIL POSTPROCESS SWSCALE)
  set_component_found(${_component})
endforeach ()

# Compile the list of required vars
set(_FFmpeg_REQUIRED_VARS FFMPEG_LIBRARIES FFMPEG_INCLUDE_DIRS)
foreach (_component ${FFmpeg_FIND_COMPONENTS})
  list(APPEND _FFmpeg_REQUIRED_VARS ${_component}_LIBRARIES ${_component}_INCLUDE_DIRS)
endforeach ()

# Give a nice error message if some of the required vars are missing.
find_package_handle_standard_args(FFmpeg DEFAULT_MSG ${_FFmpeg_REQUIRED_VARS})
