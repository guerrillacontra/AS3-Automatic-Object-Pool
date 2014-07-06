/**
 * Created by James Wrightson http://www.earthshatteringcode.com
 */
package com.pooling
{
	
	import flash.utils.Dictionary;
	
	/**
	 * An object pool that can store a collection of multiple sub-lists of
	 * different objects.
	 * 
	 * Simply fetch a object from the pool when you want, and the pool
	 * will automatically create an instance (or fetch a recycled one)
	 * and return it to you for usage.
	 * 
	 * When finished make sure you "recycle" the object so that it is
	 * back in the pool.
	 * 
	 * By default, there is automatic field variable recycling which allows
	 * your fields to be reset automatically when recycled.
	 * 
	 * It is recommended to keep the initial fields within an object that is to
	 * be pooled, simple and default - as the default values will be copied over
	 * when recycled unless custom pooled.
	 * 
	 * If you require specific pooling behaviour ensure the object implements
	 * the "ICustomPoolable" interface.
	 */
	public final class ObjectPool
	{
		
		/**
		 * Create a new ObjectPool
		 * @param	newFetchPrefetchCount For any object type that is fetched, if the pool requires new
		 * instances, how many of them should the pool generate at a time? (best to keep this value fairly low
		 * around 1 or 2).
		 */
		public function ObjectPool(newFetchPrefetchCount:int):void
		{
			if (newFetchPrefetchCount <= 0 ) throw  new Error("Must be >= 1");
			
			_newItemPrefetchCount = newFetchPrefetchCount;
		}
		
		/**
		 * Fetch an object of a known type from the pool.
		 * @param	type
		 * @return
		 */
		[Inline]
		public function fetch(type:Class):*
		{
			if (!_pools[type])
			{
				_pools[type] = new ObjectPoolList(type, _newItemPrefetchCount);
			}
			
			var poolList:ObjectPoolList = _pools[type];
			
			return poolList.fetch();
		}
		
		/**
		 * Recycle an object that was previously "fetch'd" from the pool
		 * so it can be re-used.
		 * 
		 * By default a recycled object will have its fields set to the default
		 * value based on an objects signiture.
		 * 
		 * If you require custom recycle behaviour ensure your object implements
		 * the "ICustomPoolable" interface.
		 * 
		 * @param	object
		 */
		[Inline]
		public function recycle(object:Object):void
		{
			var poolList:ObjectPoolList = _pools[object.constructor];
			poolList.recycle(object);
		}
		
		/**
		 * Clear a specific pool based on its type as if it where
		 * never created.
		 * @param	type
		 */
		public function clearPoolList(type:Class):void
		{
			var poolList:ObjectPoolList = _pools[type];
			poolList.clear();
		}
		
		/**
		 * Clear all pool lists.(basically reset the entire object pool).
		 */
		public function clearAllPoolLists():void
		{
			for (var k:String in _pools)
			{
				_pools[k].clear();
			}
		}
		
		/**
		 * Used to check if an object was "fetch'd" from this object pool.
		 * @param	object
		 * @return True if the object belongs to this pool.
		 */
		public function isFromPool(object:Object):Boolean
		{
			var poolList:ObjectPoolList = _pools[object.constructor];
			return poolList.isFromPool(object);
		}
		
		private var _pools:Dictionary = new Dictionary();
		private var _newItemPrefetchCount:int;
	
	}
}

import flash.utils.Dictionary;
import com.pooling.ICustomPoolable;
import flash.utils.describeType;

final class ObjectPoolList
{
	public function ObjectPoolList(type:Class, prefetchCount:int):void
	{
		_prefetchCount = prefetchCount;
		_defaultInstance = new type();
		_type = type;
		
		//We want to cache this list to not create garbage and allow fast
		//meta-lookup.
		var xmllist:XMLList = describeType(_defaultInstance)..variable;
		
		for (var i:int = 0; i < xmllist.length(); i++)
		{
			_xmls[i] = xmllist[i].@name;
		}
	
	}
	
	[Inline]
	public function expand():void
	{
		var instance:Object = new _type();
		_list[_length] = instance;
		_length++;
		_availabilityLookup[instance] = true;
	}
	
	[Inline]
	public function fetch():*
	{
		if (_length == 0)
		{
			for (var i:int = 0; i < _prefetchCount; i++)
				expand();
		}
		
		var item:Object = _list[_length - 1];
		_length--;
		
		_availabilityLookup[item] = false;
		
		return item;
	}
	
	[Inline]
	public function recycle(object:*):void
	{
		
		if (_availabilityLookup[object])
		{
			throw new Error(
			"Object cannot be recycled in pool.\n" +
			"Ensure the object has not all ready been recycled before"
			);
		}
		
		var poolable:ICustomPoolable = object as ICustomPoolable;
		
		if (poolable)
		{
			poolable.onPooled();
		}
		else
		{
			//Apply dynamic field copy.
			for (var i:int = 0; i < _xmls.length; i++)
			{
				object[_xmls[i]] = _defaultInstance[_xmls[i]];
			}
		}
		
		_list[_length] = object;
		_length++;
		
		_availabilityLookup[object] = true;
	}
	
	public function clear():void
	{
		_length = 0;
		_list.length = 0;
		_availabilityLookup = new Dictionary();
	}
	
	public function isFromPool(object:Object):Boolean
	{
		return _availabilityLookup[object] != undefined;
	}
	
	/**
	 * Used to keep track of what objects where created in the pool
	 * and are the in use.
	 */
	private var _availabilityLookup:Dictionary = new Dictionary();
	private var _xmls:Vector.<XMLList> = new Vector.<XMLList>();
	private var _defaultInstance:Object;
	private var _list:Array = [];
	private var _length:int = 0;
	private var _type:Class;
	private var _prefetchCount:int;

}