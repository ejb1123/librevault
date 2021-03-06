install(CODE "set(CMAKE_INSTALL_LOCAL_ONLY ON)")

if(OS_WINDOWS)
	set(LV_PACKAGING_PATH NO CACHE PATH "Base path for packaging purposes")
	if(NOT LV_PACKAGING_PATH)
		message(WARNING "Packaging directory is not set")
	endif()

	set(LV_INTALLER_SOURCE "${LV_PACKAGING_PATH}/release")

	# Daemon
	if(OS_64bit)
		set(LV_DAEMON_PATH "${LV_INTALLER_SOURCE}/x64")
	elseif(OS_32bit)
		set(LV_DAEMON_PATH "${LV_INTALLER_SOURCE}/x32")
	endif()

	# GUI
	if(BUILD_DAEMON)
		install(PROGRAMS $<TARGET_FILE:librevault-daemon> DESTINATION ${LV_DAEMON_PATH} COMPONENT librevault-package)
	endif()
	if(BUILD_GUI)
		install(PROGRAMS $<TARGET_FILE:librevault-gui> DESTINATION ${LV_INTALLER_SOURCE} COMPONENT librevault-package)
	endif()

	# Prerequisites
	if(BUILD_DAEMON)
		install(CODE "
		include(GetPrerequisites)
		get_prerequisites(\"${LV_DAEMON_PATH}/librevault-daemon.exe\" DAEMON_DEPENDENCIES 1 1 \"\" \"\")
		foreach(DEPENDENCY_FILE \${DAEMON_DEPENDENCIES})
			gp_resolve_item(\"${LV_DAEMON_PATH}/librevault-daemon.exe\" \"\${DEPENDENCY_FILE}\" \"\" \"\" resolved_file)
			file(INSTALL \${resolved_file} DESTINATION ${LV_DAEMON_PATH})
		endforeach()
		" COMPONENT librevault-package)
	endif()
	if(BUILD_GUI)
		install(CODE "
		include(GetPrerequisites)
		get_prerequisites(\"${LV_INTALLER_SOURCE}/librevault-gui.exe\" GUI_DEPENDENCIES 1 1 \"\" \"\")
		foreach(DEPENDENCY_FILE \${GUI_DEPENDENCIES})
			gp_resolve_item(\"${LV_INTALLER_SOURCE}/librevault-gui.exe\" \"\${DEPENDENCY_FILE}\" \"\" \"\" resolved_file)
			file(INSTALL \${resolved_file} DESTINATION ${LV_INTALLER_SOURCE})
		endforeach()
		" COMPONENT librevault-package)
	endif()

	# Install script
	file(GLOB INSTALLSCRIPTS packaging/innosetup/*)
	configure_file(packaging/innosetup/Librevault.iss Librevault.iss @ONLY)
	install(FILES ${INSTALLSCRIPTS} DESTINATION ${LV_PACKAGING_PATH} COMPONENT librevault-installscripts)
	install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Librevault.iss DESTINATION ${LV_PACKAGING_PATH} COMPONENT librevault-installscripts)

elseif(OS_LINUX)
	if(BUILD_DAEMON)
		install(PROGRAMS $<TARGET_FILE:librevault-daemon> DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)
	endif()
	if(BUILD_GUI)
		install(PROGRAMS $<TARGET_FILE:librevault-gui> DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)
		install(FILES "gui/resources/Librevault.desktop" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
		install(FILES "gui/resources/librevault_icon.svg" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps RENAME "librevault.svg")
	endif()
	if(BUILD_DAEMON AND BUILD_GUI AND BUILD_STATIC)
		include(InstallQt5Plugin)

		list(APPEND DEPENDENCY_BINARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/librevault-daemon)
		list(APPEND DEPENDENCY_BINARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/librevault-gui)

		# Install Qt5 plugins and library dependencies
		set(BUNDLE_PLUGINS_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/qt5/plugins)
		install_qt5_plugin("Qt5::QXcbIntegrationPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgIconPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")

		list(APPEND DEPENDENCY_BINARIES ${QT_PLUGIN})

		list(APPEND DEPENDENCY_RESOLVE_PATHS "${Qt5_DIR}/../..")

		install(CODE "
			include(GetPrerequisites)
			foreach(DEPENDENCY_BINARY ${DEPENDENCY_BINARIES})
				get_prerequisites(\"\${DEPENDENCY_BINARY}\" DEPENDENT_BINARIES 1 1 \"\" \"${DEPENDENCY_RESOLVE_PATHS}\")
				foreach(DEPENDENT_BINARY \${DEPENDENT_BINARIES})
					gp_resolve_item(\"\${DEPENDENCY_BINARY}\" \"\${DEPENDENT_BINARY}\" \"\" \"\" resolved_file)
					get_filename_component(resolved_file \${resolved_file} ABSOLUTE)
					gp_append_unique(PREREQUISITE_LIBS \${resolved_file})
					get_filename_component(file_canonical \${resolved_file} REALPATH)
					gp_append_unique(PREREQUISITE_LIBS \${file_canonical})
				endforeach()
			endforeach()

			list(SORT PREREQUISITE_LIBS)
			foreach(PREREQUISITE_LIB \${PREREQUISITE_LIBS})
				file(INSTALL \${PREREQUISITE_LIB} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
			endforeach()
		" COMPONENT librevault-package)

		# qt.conf
		install(FILES "packaging/appimage/qt.conf" DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)

		# Install AppImage dependencies: AppRun, .desktop file and icon
		set(APPDIR_ROOT "${CMAKE_INSTALL_PREFIX}/..")
		install(FILES "packaging/appimage/AppRun" DESTINATION "${APPDIR_ROOT}")
		install(FILES "gui/resources/Librevault.desktop" DESTINATION "${APPDIR_ROOT}")
		install(FILES "gui/resources/librevault_icon.svg" DESTINATION "${APPDIR_ROOT}" RENAME "librevault.svg")

		install(CODE "
			execute_process(COMMAND /bin/chmod \"+x\" \"${APPDIR_ROOT}/AppRun\")
		" COMPONENT librevault-package)
	endif()
elseif(OS_FREEBSD)
	if(BUILD_DAEMON)
		install(PROGRAMS $<TARGET_FILE:librevault-daemon> DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)
	endif()
	if(BUILD_GUI)
		install(PROGRAMS $<TARGET_FILE:librevault-gui> DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)
		install(FILES "gui/resources/Librevault.desktop" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
		install(FILES "gui/resources/librevault_icon.svg" DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps RENAME "librevault.svg")
	endif()
	if(BUILD_DAEMON AND BUILD_GUI AND BUILD_STATIC)
		include(InstallQt5Plugin)

		list(APPEND DEPENDENCY_BINARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/librevault-daemon)
		list(APPEND DEPENDENCY_BINARIES ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/librevault-gui)

		# Install Qt5 plugins and library dependencies
		set(BUNDLE_PLUGINS_PATH ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/qt5/plugins)
		install_qt5_plugin("Qt5::QXcbIntegrationPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgIconPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")

		list(APPEND DEPENDENCY_BINARIES ${QT_PLUGIN})

		list(APPEND DEPENDENCY_RESOLVE_PATHS "${Qt5_DIR}/../..")

		install(CODE "
			include(GetPrerequisites)
			foreach(DEPENDENCY_BINARY ${DEPENDENCY_BINARIES})
				get_prerequisites(\"\${DEPENDENCY_BINARY}\" DEPENDENT_BINARIES 1 1 \"\" \"${DEPENDENCY_RESOLVE_PATHS}\")
				foreach(DEPENDENT_BINARY \${DEPENDENT_BINARIES})
					gp_resolve_item(\"\${DEPENDENCY_BINARY}\" \"\${DEPENDENT_BINARY}\" \"\" \"\" resolved_file)
					get_filename_component(resolved_file \${resolved_file} ABSOLUTE)
					gp_append_unique(PREREQUISITE_LIBS \${resolved_file})
					get_filename_component(file_canonical \${resolved_file} REALPATH)
					gp_append_unique(PREREQUISITE_LIBS \${file_canonical})
				endforeach()
			endforeach()

			list(SORT PREREQUISITE_LIBS)
			foreach(PREREQUISITE_LIB \${PREREQUISITE_LIBS})
				file(INSTALL \${PREREQUISITE_LIB} DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
			endforeach()
		" COMPONENT librevault-package)

		# qt.conf
		install(FILES "packaging/appimage/qt.conf" DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT librevault-package)
	endif()
elseif(OS_MAC)
	set(CPACK_GENERATOR "Bundle")
	set(CPACK_PACKAGE_FILE_NAME "Librevault")
	# DragNDrop
	set(CPACK_DMG_FORMAT "ULFO")
	set(CPACK_DMG_DS_STORE "${CMAKE_SOURCE_DIR}/packaging/osx/DS_Store.in")
	set(CPACK_DMG_BACKGROUND_IMAGE "${CMAKE_SOURCE_DIR}/packaging/osx/background.tiff")
	# Bundle
	set(CPACK_BUNDLE_NAME "Librevault")
	set(CPACK_BUNDLE_PLIST_SOURCE "${CMAKE_SOURCE_DIR}/packaging/osx/Info.plist")
	set(CPACK_BUNDLE_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist")
	set(CPACK_BUNDLE_ICON "${CMAKE_SOURCE_DIR}/packaging/osx/Librevault.icns")

	# Apple Code Signing. Change if trying to build anywhere else!
	if(NOT LV_NO_SIGN)
		set(CPACK_BUNDLE_APPLE_CERT_APP "814C24AEF04E33147793E6E2C55454F4062A2535")
	endif()

	configure_file("${CPACK_BUNDLE_PLIST_SOURCE}" "${CPACK_BUNDLE_PLIST}" @ONLY)

	if(BUILD_DAEMON)
		install(PROGRAMS $<TARGET_FILE:librevault-daemon> DESTINATION ../MacOS COMPONENT librevault-package)
	endif()
	if(BUILD_GUI)
		install(PROGRAMS $<TARGET_FILE:librevault-gui> DESTINATION ../MacOS COMPONENT librevault-package)
	endif()
	install(FILES ${CPACK_BUNDLE_PLIST} DESTINATION ../ COMPONENT librevault-package)

	install(FILES "packaging/osx/qt.conf" DESTINATION ../Resources COMPONENT librevault-package)
	install(FILES "packaging/osx/dsa_pub.pem" DESTINATION ../Resources COMPONENT librevault-package)

	# Bundle plugin path
	set(BUNDLE_PLUGINS_PATH "../../Contents/PlugIns")

	# Qt5 plugins
	if(BUILD_GUI)
		include(InstallQt5Plugin)
		install_qt5_plugin("Qt5::QCocoaIntegrationPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")
		install_qt5_plugin("Qt5::QSvgIconPlugin" QT_PLUGIN "${BUNDLE_PLUGINS_PATH}")

		install(CODE "
		include(BundleUtilities)
		set(BU_CHMOD_BUNDLE_ITEMS ON)
		set(QT_PLUGIN_IN_BUNDLE \"\")
		foreach(f ${QT_PLUGIN})
			get_filename_component(QT_PLUGIN_ABSOLUTE \"\${CMAKE_INSTALL_PREFIX}/\${f}\" ABSOLUTE)
			list(APPEND QT_PLUGIN_IN_BUNDLE \"\${QT_PLUGIN_ABSOLUTE}\")
		endforeach(f)
		get_filename_component(BUNDLE_PATH \"\${CMAKE_INSTALL_PREFIX}/../..\" ABSOLUTE)
		fixup_bundle(\"\${BUNDLE_PATH}\" \"\${QT_PLUGIN_IN_BUNDLE}\" \"\")
		" COMPONENT librevault-package)
	endif()

	include(CPack)
endif()
