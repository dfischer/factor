/* :folding=explicit:collapseFolds=1: */

/*
 * $Id$
 *
 * Copyright (C) 2004 Slava Pestov.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * DEVELOPERS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package factor.compiler;

import factor.*;
import java.util.*;

public class StackEffect implements PublicCloneable, FactorExternalizable
{
	public int inD;
	public int outD;
	public int inR;
	public int outR;

	//{{{ StackEffect constructor
	public StackEffect() {}
	//}}}

	//{{{ StackEffect constructor
	public StackEffect(int inD, int outD, int inR, int outR)
	{
		this.inD = inD;
		this.outD = outD;
		this.inR = inR;
		this.outR = outR;
	} //}}}

	//{{{ compose() method
	public static StackEffect compose(StackEffect first,
		StackEffect second)
	{
		if(first == null || second == null)
			return null;

		int inD  = first.inD;
		int inR  = first.inR;
		int outD = first.outD;
		int outR = first.outR;

		if(second.inD <= outD)
			outD -= second.inD;
		else
		{
			inD += (second.inD - outD);
			outD = 0;
		}

		if(second.inR <= outR)
			outR -= second.inR;
		else
		{
			inR += (second.inR - outR);
			outR = 0;
		}

		outD += second.outD;
		outR += second.outR;

		return new StackEffect(inD,outD,inR,outR);
	} //}}}

	//{{{ decompose() method
	/**
	 * Returns a stack effect E such that compose(first,E) == second.
	 */
	public static StackEffect decompose(StackEffect first,
		StackEffect second)
	{
		if(second.inD < first.inD || second.inR < first.inR)
			throw new IllegalArgumentException();

		return new StackEffect(
			first.outD + second.inD - first.inD,
			second.outD,
			first.outR + second.inR - first.inR,
			second.outR);
	} //}}}

	//{{{ getCorePrototype() method
	public String getCorePrototype()
	{
		StringBuffer signatureBuf = new StringBuffer(
			"(Lfactor/FactorInterpreter;");

		for(int i = 0; i < inD; i++)
		{
			signatureBuf.append("Ljava/lang/Object;");
		}

		if(outD != 1)
			signatureBuf.append(")V");
		else
			signatureBuf.append(")Ljava/lang/Object;");

		return signatureBuf.toString();
	} //}}}

	//{{{ equals() method
	public boolean equals(Object o)
	{
		if(!(o instanceof StackEffect))
			return false;
		StackEffect effect = (StackEffect)o;
		return effect.inD == inD
			&& effect.outD == outD
			&& effect.inR == inR
			&& effect.outR == outR;
	} //}}}

	//{{{ toString() method
	public String toString()
	{
		StringBuffer buf = new StringBuffer("( ");
		for(int i = 0; i < inD; i++)
		{
			buf.append("X ");
		}
		for(int i = 0; i < inR; i++)
		{
			buf.append("r:X ");
		}
		buf.append("--");
		for(int i = 0; i < outD; i++)
		{
			buf.append(" X");
		}
		for(int i = 0; i < outR; i++)
		{
			buf.append(" r:X");
		}
		buf.append(" )");
		return buf.toString();
	} //}}}

	//{{{ clone() method
	public Object clone()
	{
		return new StackEffect(inD,outD,inR,outR);
	} //}}}
}
