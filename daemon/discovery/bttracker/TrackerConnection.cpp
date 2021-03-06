/* Copyright (C) 2016 Alexander Shishenko <alex@shishenko.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * In addition, as a special exception, the copyright holders give
 * permission to link the code of portions of this program with the
 * OpenSSL library under certain conditions as described in each
 * individual source file, and distribute linked combinations
 * including the two.
 * You must obey the GNU General Public License in all respects
 * for all of the code used other than OpenSSL.  If you modify
 * file(s) with this exception, you may extend this exception to your
 * version of the file(s), but you are not obligated to do so.  If you
 * do not wish to do so, delete this exception statement from your
 * version.  If you delete this exception statement from all source
 * files in the program, then also delete it here.
 */
#include "UDPTrackerConnection.h"
#include "folder/FolderGroup.h"
#include "nodekey/NodeKey.h"

namespace librevault {

TrackerConnection::TrackerConnection(url tracker_address,
                                     std::shared_ptr<FolderGroup> group_ptr,
                                     BTTrackerDiscovery& tracker_discovery,
                                     NodeKey& node_key, PortMappingService& port_mapping, io_service& io_service) :
		io_service_(io_service),
		tracker_discovery_(tracker_discovery),
		node_key_(node_key),
		port_mapping_(port_mapping),
		tracker_address_(tracker_address),
		group_ptr_(group_ptr) {
	assert(tracker_address_.scheme == "udp");
	if(tracker_address_.port == 0)
		tracker_address_.port = 80;
}

TrackerConnection::~TrackerConnection() {}

btcompat::info_hash TrackerConnection::get_info_hash() const {
	return btcompat::get_info_hash(group_ptr_->hash());
}

btcompat::peer_id TrackerConnection::get_peer_id() const {
	return btcompat::get_peer_id(node_key_.public_key());
}

} /* namespace librevault */
