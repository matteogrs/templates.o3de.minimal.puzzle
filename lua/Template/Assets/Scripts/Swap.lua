-- Copyright (c) 2025 Matteo Grasso
-- 
--     https://github.com/matteogrs/templates.o3de.minimal.puzzle
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

local InputMultiHandler = require("Scripts.Utils.Components.InputUtils")

local Swap =
{
	Properties =
	{
		Rows = 3,
		Columns = 3,
		TileIds =
		{
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId(),
			EntityId()
		},
		FocusScale = 1.25,
		SelectScale = 0.75
	}
}

function Swap:OnActivate()
	if (self.Properties.Rows * self.Properties.Columns) ~= #self.Properties.TileIds then
		Debug.Log("ERROR: Tiles do not match the board size (" .. self.Properties.Rows .. "x" .. self.Properties.Columns .. ")")
		return
	end

	self.currentRow = 0
	self.currentColumn = 0
	self.currentTileIndex = 1
	self.currentTileId = self.Properties.TileIds[self.currentTileIndex]	

	TransformBus.Event.SetLocalUniformScale(self.currentTileId, self.Properties.FocusScale)
	self.isSelected = false

	self.nextRow = self.currentRow
	self.nextColumn = self.currentColumn

	self.inputHandlers = InputMultiHandler.ConnectMultiHandlers
	{
		[InputEventNotificationId("HorizontalMove")] =
		{
			OnPressed = function(value) self:OnColumnChanged(value) end
		},
		[InputEventNotificationId("VerticalMove")] =
		{
			OnPressed = function(value) self:OnRowChanged(value) end
		},
		[InputEventNotificationId("Select")] =
		{
			OnPressed = function(value) self:OnSelectChanged(value) end
		}
	}
end

function Swap:OnColumnChanged(value)
	self.nextColumn = (self.currentColumn + Math.Round(value)) % self.Properties.Columns
	self:OnCellChanged()
end

function Swap:OnRowChanged(value)
	self.nextRow = (self.currentRow + Math.Round(value)) % self.Properties.Rows
	self:OnCellChanged()
end

function Swap:OnCellChanged()
	local nextTileIndex = 1 + (self.nextRow * self.Properties.Columns) + self.nextColumn
	local nextTileId = self.Properties.TileIds[nextTileIndex]

	if self.isSelected then
		local nextTile = TransformBus.Event.GetChildren(nextTileId)[1]
		local isEmpty = TagComponentRequestBus.Event.HasTag(nextTile, Crc32("Empty"))

		if isEmpty then
			local currentPosition = TransformBus.Event.GetLocalTranslation(self.currentTileId)
			local nextPosition = TransformBus.Event.GetLocalTranslation(nextTileId)

			TransformBus.Event.SetLocalTranslation(self.currentTileId, nextPosition)
			self.Properties.TileIds[nextTileIndex] = self.currentTileId

			TransformBus.Event.SetLocalTranslation(nextTileId, currentPosition)			
			self.Properties.TileIds[self.currentTileIndex] = nextTileId
		else
			self.nextRow = self.currentRow
			self.nextColumn = self.currentColumn

			return
		end
	else
		TransformBus.Event.SetLocalUniformScale(self.currentTileId, 1.0)
		TransformBus.Event.SetLocalUniformScale(nextTileId, self.Properties.FocusScale)

		self.currentTileId = nextTileId
	end

	self.currentRow = self.nextRow
	self.currentColumn = self.nextColumn
	self.currentTileIndex = nextTileIndex
end

function Swap:OnSelectChanged(value)
	local scale
	if self.isSelected then
		scale = self.Properties.FocusScale
	else
		local currentTile = TransformBus.Event.GetChildren(self.currentTileId)[1]
		local isEmpty = TagComponentRequestBus.Event.HasTag(currentTile, Crc32("Empty"))

		if isEmpty then
			return
		end

		scale = self.Properties.SelectScale
	end

	TransformBus.Event.SetLocalUniformScale(self.currentTileId, scale)
	self.isSelected = not self.isSelected
end

function Swap:OnDeactivate()
	if self.inputHandlers ~= nil then
		self.inputHandlers:Disconnect()
		self.inputHandlers = nil
	end
end

return Swap
