// Copyright 2018-2019 Authors of Cilium
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package cmd

import (
	"net"
	"strconv"

	"github.com/cilium/cilium/api/v1/client/daemon"
	"github.com/cilium/cilium/api/v1/models"

	"github.com/spf13/cobra"
)

var nodeNeighInsertCmd = &cobra.Command{
	Use:     "insert ( <node identity> <node IP> ) ",
	Short:   "Insert node neighbor tables",
	Example: "cilium node neigh insert 5 10.10.10.10",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) != 2 {
			Usagef(cmd, "Missing node identity and/or node IP")
		}

		id, err := strconv.ParseInt(args[0], 10, 64)
		if err != nil {
			Fatalf("Invalid node identity: %v\n", err)
		}

		if ip := net.ParseIP(args[1]); ip == nil {
			Fatalf("Invalid IP address %q\n", args[1])
		}

		if _, err := client.Daemon.PutClusterNodesNeigh(
			daemon.NewPutClusterNodesNeighParams().WithRequest(&models.NodeNeighRequest{
				ID: id,
				IP: args[1],
			}),
		); err != nil {
			Fatalf("Cannot insert node into neighbor table: %v\n", err)
		}
	},
}

func init() {
	nodeNeighCmd.AddCommand(nodeNeighInsertCmd)
}
