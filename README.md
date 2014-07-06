# AS3-Automatic-Object-Pool

An automatic object pool for AS3.

A simple and fast object pool that can automatically recycle an object based on the objects default values
making it very easy to use.

## About

When dealing with memory fragmentation, especially when targeting mobile platforms, one of the best solutions
is to simply re-use instances and block them from garbage collection.

An object pool allows you to manage the fetching and recyling aspects in your code, so that you can re-use
instances with minimal hassle.

## How To use

### Setup

First of all you will want to create an instance of the object pool:

'''
var pool:ObjectPool = new ObjectPool(**prefetchCount**);
'''

The prefetchCount is used to decide how many instances to create if there are no more
instances left in the pool.

For scenarios that require frequent creation/recycling you will want a larger prefetchCount.

In most situations, 1 or 2 is a good value to set.

### Fetch

Now that the ObjectPool is setup, we can use it!

Here is an example of getting an item from the pool:

'''
var point:Point = pool.fetch(Point);
trace(point.x) // "0"
trace(point.y) // "0"
'''

At this stage, the variable "point" will be recycled and reset to its default values (in as3.geom.Point
it will be x:0,y:0).

### Manipulation

Aha I caught you off guard! I don't have any advice for how you use your object, do with it as you wish!

### Recycle

When you want to return your object to the pool simply:

'''
pool.recycle(point);
'''

And the point will be recycled and sent back to the pool.

**WARNING: Do not use your recycled instance (ie point). It has been reset and if you mess with it
its values will be different.**

### Advanced use

If you require custom recycling behaviour (maybe you have a complex object that needs to be reset specifically),
you can make your object implement the "ICustomPoolable" interface.

For example:

public function onPooled():void{
this.database.disconnect();
this.connection = Connections.getCurrentLegalConnection();
}

(note: I have no idea what my scenario is above is about, but you get the idea. Custom recycle behaviour!).



