
var ANIMATIONS_GLOBAL_ID = 0,
    CURRENT_ANIMATIONS = {},

    ANIMATION_END_EVENT_NAME,
    ANIMATION__PROPERTY,
    ANIMATION_NAME_PROPERTY,
    ANIMATION_DURATION_PROPERTY,
    ANIMATION_TIMING_FUNCTION_PROPERTY,
    ANIMATION_FILL_MODE_PROPERTY,
    ANIMATION_KEYFRAMES_RULE;

var defineCSSProperties = function()
{
    if (this.done)
        return;

    ANIMATION_END_EVENT_NAME            = CPBrowserStyleProperty("animationend"),
    ANIMATION_PROPERTY                  = CPBrowserCSSProperty("animation"),
    ANIMATION_NAME_PROPERTY             = CPBrowserCSSProperty("animation-name"),
    ANIMATION_DURATION_PROPERTY         = CPBrowserCSSProperty("animation-duration"),
    ANIMATION_TIMING_FUNCTION_PROPERTY  = CPBrowserCSSProperty("animation-timing-function"),
    ANIMATION_FILL_MODE_PROPERTY        = CPBrowserCSSProperty("animation-fill-mode"),
    ANIMATION_KEYFRAMES_RULE            = "@" + ANIMATION_PROPERTY.substring(0, ANIMATION_PROPERTY.indexOf("animation")) + "keyframes";

    this.done = true;
}

CSSAnimation = function(aTarget/*DOM Element*/, anIdentifier)
{
    defineCSSProperties();

    if (!anIdentifier)
        anIdentifier = ANIMATIONS_GLOBAL_ID++;

    var animationName = "anim_" + anIdentifier,
        animation = CURRENT_ANIMATIONS[anIdentifier];

    if (animation)
        console.warn("Animation "+ anIdentifier + " is already in use. Ignoring.");
    else
    {
        this.target = aTarget;
        this.identifier = anIdentifier;
        this.animationName = animationName;
        this.listener = null;
        this.styleElement = null;
        this.propertyanimations = [];
        this.animationsnames = [];
        this.animationstimingfunctions = [];
        this.animationsdurations = [];
        this.islive = false;
        this.didBuildDOMElements = false;
        this.removeAnimationPropertyOnCompletion = true;

        animation = this;
        CURRENT_ANIMATIONS[anIdentifier] = animation;
    }

    return animation;
}

CSSAnimation.prototype.addPropertyAnimation = function(propertyName/*String*/, valueFunction/*Function*/, aDuration/*float*/, aKeyTimes/*d, [d]*/, aValues/*Array*/, aTimingFunctions/*[d,d,d,d],[[d,d,d,d]]*/, aCompletionfunction/*Function*/)
{
    if (this.islive)
        return false;
// TODO: If a property already exist, replace its values & valueFunctions.

    var name = this.animationName + "_" + propertyName;

    var animation = {name:name,
                     property:propertyName,
                     valuefunction:valueFunction,
                     keytimes:aKeyTimes,
                     values:aValues,
                     duration:aDuration,
                     completionfunction:aCompletionfunction};

    var animationTimingFunction;
    if (aTimingFunctions && (aTimingFunctions[0] instanceof Array))
    {
        animation.keyframestimingFunctions = aTimingFunctions;
        // dummy timing function overriden by keyframes timings functions
        animationTimingFunction = "linear";
    }
    else
        animationTimingFunction = "cubic-bezier(" + aTimingFunctions + ")";

    this.animationstimingfunctions.push(animationTimingFunction);

    this.propertyanimations.push(animation);
    this.animationsnames.push(name);
    this.animationsdurations.push(aDuration + "s");

    return true;
}

CSSAnimation.prototype.keyFrames = function()
{
    var keyframesRules = [];

    var count = this.propertyanimations.length;
    for (var i = 0; i < count; i++)
    {
        var animation = this.propertyanimations[i],
            property = animation.property,
            valuefunction = animation.valuefunction,
            keytimes = animation.keytimes,
            values = animation.values,
            timingFunctions = animation.keyframestimingFunctions;

        var keyframes = [],
            keytimescount = keytimes.length,
            start_value = values[0];

        for (var j = 0; j < keytimescount; j++)
        {
            var keytime = keytimes[j],
                value = values[j],
                timingFunction;

            if (valuefunction !== nil)
                value = valuefunction(start_value, value);

            var keyframeContent = property + ": " + value + ";";

            if (timingFunctions && timingFunctions.length && (timingFunction = timingFunctions[j]))
            {
                keyframeContent += ANIMATION_TIMING_FUNCTION_PROPERTY + ":cubic-bezier(" + timingFunction + ");";
            }

            var keyframe = "\t" + Math.round(keytime * 100) + "% {\n\t\t" + keyframeContent + "\n\t}\n";
            keyframes.push(keyframe);
        }
        // TODO ! Add keyframe rule to CPCompatibility
        var rule = ANIMATION_KEYFRAMES_RULE + " " + animation.name + " {\n" + keyframes.join(" ") + "}\n";
        keyframesRules.push(rule);
    }

    return keyframesRules.join("\n");
}

CSSAnimation.prototype.appendKeyFramesRule = function()
{
    var styleElement = this.createKeyFramesStyleElement(),
        keyframesText = this.keyFrames(),
        nodeText = document.createTextNode(keyframesText);

    styleElement.appendChild(nodeText);
    document.head.appendChild(styleElement);
}

CSSAnimation.prototype.createKeyFramesStyleElement = function()
{
    if (!this.styleElement)
    {
        var styleElement = document.createElement("style");
        styleElement.setAttribute("type", "text/css");

        this.styleElement = styleElement;
    }

    return this.styleElement;
}

CSSAnimation.prototype.endEventListener = function()
{
    var animation = this,
        animationsNames = this.animationsnames,
        inFlightAnimationsNames = animationsNames.slice();

    if (!animation.listener)
    {
        var AnimationEndListener = function(event)
        {
            var idx = inFlightAnimationsNames.indexOf(event.animationName);
            if (idx !== -1)
                inFlightAnimationsNames.splice(idx, 1);

            if (inFlightAnimationsNames.length == 0)
            {
                for (var i = 0; i < animationsNames.length; i++)
                {
                    var completion = animation.completionFunctionForAnimationName(animationsNames[i]);
                    if (completion)
                        completion();
                }

                var eventTarget = event.target,
                    style = eventTarget.style;

                if (animation.removeAnimationPropertyOnCompletion)
                    style.removeProperty(ANIMATION_NAME_PROPERTY);

                style.removeProperty(ANIMATION_DURATION_PROPERTY);
                style.removeProperty(ANIMATION_FILL_MODE_PROPERTY);
                style.removeProperty("-webkit-backface-visibility");

                if (animation.animationstimingfunctions.length)
                   style.removeProperty(ANIMATION_TIMING_FUNCTION_PROPERTY);

                removeFromParent(animation.styleElement);

                eventTarget.removeEventListener(ANIMATION_END_EVENT_NAME, AnimationEndListener);
                animation.listener = null;
                delete (CURRENT_ANIMATIONS[animation.identifier]);
            }
        };

        this.listener = AnimationEndListener;
    }

    return this.listener;
}

CSSAnimation.prototype.completionFunctionForAnimationName = function(aName)
{
    var propanims = this.propertyanimations,
        count = propanims.length;

    while (count--)
    {
        var anim = propanims[count];
        if (anim.name == aName)
            return anim.completionfunction;
    }

    return null;
}

CSSAnimation.prototype.addAnimationEndEventListener = function()
{
    var listener = this.endEventListener();
    this.target.addEventListener(ANIMATION_END_EVENT_NAME, listener, false);
}

CSSAnimation.prototype.setTargetStyleProperties = function()
{
    var style = this.target.style;

    if (this.animationstimingfunctions.length)
        style.setProperty(ANIMATION_TIMING_FUNCTION_PROPERTY, this.animationstimingfunctions.join(","));

    style.setProperty(ANIMATION_DURATION_PROPERTY, this.animationsdurations.join(","));

    style.setProperty(ANIMATION_FILL_MODE_PROPERTY, "forwards");

//    http://webdesign.tutsplus.com/tutorials/htmlcss-tutorials/css3-animations-the-hiccups-and-bugs-youll-want-to-avoid/
    style.setProperty("-webkit-backface-visibility", "hidden");
}

CSSAnimation.prototype.buildDOMElements = function()
{
    this.appendKeyFramesRule();

    this.addAnimationEndEventListener();

    this.setTargetStyleProperties();

    this.didBuildDOMElements = true;
}

CSSAnimation.prototype.setRemoveAnimationPropertyOnCompletion = function(flag)
{
    this.removeAnimationPropertyOnCompletion = flag;
}

CSSAnimation.prototype.start = function()
{
    if (this.propertyanimations.length == 0 || this.islive)
        return false;

    if (!this.didBuildDOMElements)
        this.buildDOMElements();

    this.target.style.setProperty(ANIMATION_NAME_PROPERTY, this.animationsnames.join(","));

    this.islive = true;

    return true;
}

var removeFromParent= function(aNode)
{
    var parentNode = aNode.parentNode;
    if (parentNode)
        parentNode.removeChild(aNode);
}
